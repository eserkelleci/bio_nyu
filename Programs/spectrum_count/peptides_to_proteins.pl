#!c:/perl/bin/perl.exe
#

$error=0;
if ($ARGV[0]=~/\w/) { $filename1=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $filename2=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $minimum=$ARGV[2];} else { $minimum=3; }
if ($ARGV[3]=~/\w/) { $db_dir=$ARGV[3];} else { $error=1; }

$filename_res=$filename2;
$filename_res=~s/\.txt$//i;
$filename_res=~s/^.*([\\\/])([\\\/]+)$/$1/g;
$filename_res="$filename1-$filename_res-$minimum";

if ($error==0)
{
	open (IN,"$filename1") || die "Could not open $filename1\n";
	$line=<IN>;
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)$/)
		{
			$pep=$1;
			$count=$2;
			$peptides1{$pep}=$count;
			$peptides{$pep}=1;
		}
	}
	close(IN);
	open (IN,"$filename2") || die "Could not open $filename1\n";
	$line=<IN>;
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)$/)
		{
			$pep=$1;
			$count=$2;
			$peptides2{$pep}=$count;
			$peptides{$pep}=1;
		}
	}
	close(IN);
	

	foreach $pep (keys %peptides)
	{
		$temp1=$peptides1{$pep}; if ($temp1!~/\w/) { $temp1=0; }
		$temp2=$peptides2{$pep}; if ($temp2!~/\w/) { $temp2=0; }
		if ($peptides1{$pep}>=$minimum or $peptides2{$pep}>=$minimum)
		{
			print OUT qq!$pep\t$temp1\t$temp2\n!;
		}
		else
		{
			print OUT_ qq!$pep\t$temp1\t$temp2\n!;
		}
	}	
	close(OUT);	
	close(OUT_);
	
	opendir(dir,"$db_dir");
	@dbs = readdir dir;
	foreach $db (@dbs)
	{
		if ($db=~/\.fasta/i)
		{
			if (open (IN,"$db_dir/$db"))
			{
				#print "$db\n";	
				$name="";
				$description="";
				$sequence="";
				$count_seq=0;
				while ($line=<IN>)
				{
					chomp($line);
					if ($line=~/^>(\S+)\s*(.*)$/)
					{
						$name_=$1;
						$description_=$2;
						$description=~s/[\t\n\r]/,/g;
						#if ($count_seq%1000==0) { print "$count_seq\n"; }
						$count_seq++;
						if ($name=~/\w/ and $sequence=~/\w/)
						{
							$PROTEIN_DESC{$name}=$description;
							$PROTEIN_SEQ{$name}=$sequence;
						}
						$name=$name_;
						$description=$description_;
						$sequence="";
					}
					else
					{
						$sequence.="$line";
					}
				}	
				if ($name=~/\w/ and $sequence=~/\w/)
				{
					$PROTEIN_DESC{$name}=$description;
					$PROTEIN_SEQ{$name}=$sequence;
				}
				close(IN);
				print "$db: $count_seq\n";
			}
		}
	}
	open (OUT,">$filename_res.txt") || die "Could not open $filename_res.txt\n";
	print OUT qq!pep\t$filename1\t$filename2\n!;
	open (OUT_,">$filename_res.few.txt") || die "Could not open $filename_res.few.txt\n";
	print OUT_ qq!pep\t$filename1\t$filename2\n!;
	foreach $pep (keys %peptides)
	{
		$temp1=$peptides1{$pep}; if ($temp1!~/\w/) { $temp1=0; }
		$temp2=$peptides2{$pep}; if ($temp2!~/\w/) { $temp2=0; }
		if ($peptides1{$pep}>=$minimum or $peptides2{$pep}>=$minimum)
		{
			print OUT qq!$pep\t$temp1\t$temp2\n!;
			$temp1_=$temp1; if ($temp1_<=0) { $temp1_=0.00001; }
			$temp2_=$temp2; if ($temp2_<=0) { $temp2_=0.00001; }
			$RATIOS[$count_ratios++]=log($temp1_/$temp2_)/log(2);
		}
		else
		{
			print OUT_ qq!$pep\t$temp1\t$temp2\n!;
		}
		foreach $name (keys %PROTEIN_SEQ)
		{
			$seq=$PROTEIN_SEQ{$name};
			$seq=~tr/Q/K/;
			$seq=~tr/I/L/;
			$pep_=$pep;
			$pep_=~tr/Q/K/;
			$pep_=~tr/I/L/;
			if ($seq=~/$pep_/)
			{
				$PROTEIN_PEPTIDE{$name}.="#$pep:$temp1,$temp2#";
				$PROTEIN_PEPTIDE_COUNT{$name}++;
				$PEPTIDE_PROTEIN{$pep}.="#$name#";
				$PEPTIDE_PROTEIN_COUNT{$pep}++;
				$PROTEIN_SPECTRUM_COUNT1{$name}+=$temp1;
				$PROTEIN_SPECTRUM_COUNT2{$name}+=$temp2;
				if ($peptides1{$pep}>=$minimum or $peptides2{$pep}>=$minimum)
				{
					$PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}+=$temp1;
					$PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}+=$temp2;
				}
			}
		}
	}
	close(OUT);	
	close(OUT_);
	@RATIOS_SORTED = sort { $a <=> $b }@RATIOS;
	if ($count_ratios % 4) { $q1=$RATIOS_SORTED[int($count_ratios/4)]; } else { $q1=($RATIOS_SORTED[$count_ratios/4] + $RATIOS_SORTED[$count_ratios/4 - 1]) / 2; }
	if ($count_ratios % 2) { $median=$RATIOS_SORTED[int($count_ratios/2)]; } else { $median=($RATIOS_SORTED[$count_ratios/2] + $RATIOS_SORTED[$count_ratios/2 - 1]) / 2; }
	if ($count_ratios*3 % 4) { $q3=$RATIOS_SORTED[int($count_ratios*3/4)]; } else { $q3=($RATIOS_SORTED[$count_ratios*3/4] + $RATIOS_SORTED[$count_ratios*3/4 - 1]) / 2; }

	foreach $name (keys %PROTEIN_PEPTIDE)
	{
		$PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}=0;
		$temp=$PROTEIN_PEPTIDE{$name};
		while($temp=~s/^#([^#]+)#//)
		{
			$pep_spectrum_count=$1;
			if ($pep_spectrum_count=~/^([^\:]+)\:([^\,]+)\,(.*)$/)
			{
				$pep=$1;
				if ($PEPTIDE_PROTEIN_COUNT{$pep}==1)
				{
					$PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}++;
				}
			}
		}
	}
				
	@GROUP_PROTEIN=();
	$group_number=-1;
	foreach $name (keys %PROTEIN_PEPTIDE)
	{
		#print qq!$group_number $name\n!;
		if ($PROTEIN_GROUP{$name}!~/\w/)
		{
			$group_number++;
			$group_number_=$group_number;
			$PROTEIN_GROUP{$name}=$group_number_;
			$GROUP_PROTEIN[$group_number_].="#$name#";
		}
		$group_number_=$PROTEIN_GROUP{$name};
		$temp=$PROTEIN_PEPTIDE{$name};
		while($temp=~s/^#([^#]+)#//)
		{
			$pep_spectrum_count=$1;
			if ($pep_spectrum_count=~/^([^\:]+)\:([^\,]+)\,(.*)$/)
			{
				$pep=$1;
				if ($PEPTIDE_GROUP{$pep}!~/\w/)
				{
					$PEPTIDE_GROUP{$pep}=$group_number_;
					$temp_=$PEPTIDE_PROTEIN{$pep};
					while($temp_=~s/^#([^#]+)#//)
					{
						$name_=$1;
						if ($PROTEIN_GROUP{$name_}!~/\w/)
						{
							$PROTEIN_GROUP{$name_}=$group_number_;
							$GROUP_PROTEIN[$group_number_].="#$name_#";
						}
					}
				}
			}
		}
	}
	$group_number++;
	open (OUT1,">$filename_res.proteins.1.txt") || die "Could not open $filename_res.proteins.1.txt\n";
	open (OUT2,">$filename_res.proteins.2.txt") || die "Could not open $filename_res.proteins.2.txt\n";
	open (OUT_ALL,">$filename_res.all-proteins.txt") || die "Could not open $filename_res.all-proteins.txt\n";
	print OUT1    qq!group\tname\tdescription\tpeptide_count\tunique_peptide_count\tspectrum_count\_$filename1\tspectrum_count\_$filename2\tlog2_ratio\tlog2_ratio_corr\tspectrum_count_gtmin\_$filename1\tspectrum_count_gtmin\_$filename2\tlog2_ratio_gtmin\tlog2_ratio_corr_gtmin\tpeptides\n!;
	print OUT2    qq!group\tname\tdescription\tpeptide_count\tunique_peptide_count\tspectrum_count\_$filename1\tspectrum_count\_$filename2\tlog2_ratio\tlog2_ratio_corr\tspectrum_count_gtmin\_$filename1\tspectrum_count_gtmin\_$filename2\tlog2_ratio_gtmin\tlog2_ratio_corr_gtmin\tpeptides\n!;
	print OUT_ALL qq!group\tname\tdescription\tpeptide_count\tunique_peptide_count\tspectrum_count\_$filename1\tspectrum_count\_$filename2\tlog2_ratio\tlog2_ratio_corr\tspectrum_count_gtmin\_$filename1\tspectrum_count_gtmin\_$filename2\tlog2_ratio_gtmin\tlog2_ratio_corr_gtmin\tpeptides\n!;
	for($i=0;$i<$group_number;$i++)
	{
		$temp=$GROUP_PROTEIN[$i];
		$j=0;
		@to_sort=();
		while($temp=~s/^#([^#]+)#//)
		{
			$name=$1;
			$to_sort[$j++]=qq!$PROTEIN_PEPTIDE_COUNT{$name}#$name!;
		}
		@sorted = sort { $b <=> $a } @to_sort;
		$k=0;
		foreach $temp (@sorted)
		{
			if ($temp=~/^([0-9]+)#(.*)$/)
			{
				$name=$2;
				if ($PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}!~/\w/) { $PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}=0; }
				if ($PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}!~/\w/) { $PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}=0; }
				$temp1=$PROTEIN_SPECTRUM_COUNT1{$name}; if ($temp1<=0) { $temp1=0.00001; }
				$temp2=$PROTEIN_SPECTRUM_COUNT2{$name}; if ($temp2<=0) { $temp2=0.00001; }
				$logratio=log($temp1/$temp2)/log(2);
				$logratio_corr=$logratio-$median;
				$temp1=$PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}; if ($temp1<=0) { $temp1=0.00001; }
				$temp2=$PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}; if ($temp2<=0) { $temp2=0.00001; }
				$logratio_gtmin=log($temp1/$temp2)/log(2);
				$logratio_gtmin_corr=$logratio_gtmin-$median;
				if ($k==0 or $PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}>=1)
				{
					print OUT1 qq!$i\t$name\t$PROTEIN_DESC{$name}\t$PROTEIN_PEPTIDE_COUNT{$name}\t$PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}\t$PROTEIN_SPECTRUM_COUNT1{$name}\t$PROTEIN_SPECTRUM_COUNT2{$name}\t$logratio\t$logratio_corr\t$PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}\t$PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}\t$logratio_gtmin\t$logratio_gtmin_corr!;
					$temp_=$PROTEIN_PEPTIDE{$name};
					while($temp_=~s/^#([^#]+)#//)
					{
						$pep_spectrum_count=$1;
						if ($pep_spectrum_count=~/^([^\:]+)\:([^\,]+)\,(.*)$/)
						{
							$pep=$1;
							print OUT1 qq!\t$pep($PEPTIDE_PROTEIN_COUNT{$pep}):($2,$3)!;
						}
					}
					print OUT1 qq!\n!;
				}
				if ($k==0 or $PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}>=2)
				{
					print OUT2 qq!$i\t$name\t$PROTEIN_DESC{$name}\t$PROTEIN_PEPTIDE_COUNT{$name}\t$PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}\t$PROTEIN_SPECTRUM_COUNT1{$name}\t$PROTEIN_SPECTRUM_COUNT2{$name}\t$logratio\t$logratio_corr\t$PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}\t$PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}\t$logratio_gtmin\t$logratio_gtmin_corr!;
					$temp_=$PROTEIN_PEPTIDE{$name};
					while($temp_=~s/^#([^#]+)#//)
					{
						$pep_spectrum_count=$1;
						if ($pep_spectrum_count=~/^([^\:]+)\:([^\,]+)\,(.*)$/)
						{
							$pep=$1;
							print OUT2 qq!\t$pep($PEPTIDE_PROTEIN_COUNT{$pep}):($2,$3)!;
						}
					}
					print OUT2 qq!\n!;
				}
				if ($printed{$name}=~/\w/)
				{
					print qq!Error: $name belongs to more than one group\n!;
				}
				$printed{$name}=1;
				print OUT_ALL qq!$i\t$name\t$PROTEIN_DESC{$name}\t$PROTEIN_PEPTIDE_COUNT{$name}\t$PROTEIN_UNIQUE_PEPTIDE_COUNT{$name}\t$PROTEIN_SPECTRUM_COUNT1{$name}\t$PROTEIN_SPECTRUM_COUNT2{$name}\t$logratio\t$logratio_corr\t$PROTEIN_SPECTRUM_COUNT1_GTMIN{$name}\t$PROTEIN_SPECTRUM_COUNT2_GTMIN{$name}\t$logratio_gtmin\t$logratio_gtmin_corr!;
				$temp_=$PROTEIN_PEPTIDE{$name};
				while($temp_=~s/^#([^#]+)#//)
				{
					$pep_spectrum_count=$1;
					if ($pep_spectrum_count=~/^([^\:]+)\:([^\,]+)\,(.*)$/)
					{
						$pep=$1;
						print OUT_ALL qq!\t$pep($PEPTIDE_PROTEIN_COUNT{$pep}):($2,$3)!;
					}
				}
				print OUT_ALL qq!\n!;
				$k++;
			}
		}
	}
	close(OUT1);
	close(OUT2);
	close(OUT_ALL);
	foreach $name (keys %PROTEIN_PEPTIDE)
	{
		if ($printed{$name}!~/\w/)
		{
			print qq!Error: $name does not belong to any group\n!;
		}
	}
}

