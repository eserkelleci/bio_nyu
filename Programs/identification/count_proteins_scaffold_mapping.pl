#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $textfile="";
my $textfile_mapping_human="";
my $textfile_mapping_mouse="";
my $peptide_number_threshold="";
my $fdr_peptide_threshold="";
my $fdr_protein_threshold="";
my $msgf_threshold="";
my $mascot_threshold="";
my $filter="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $textfile_mapping_human=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $textfile_mapping_mouse=$ARGV[2];} else { $error=1; }
if ($ARGV[3]=~/\w/) { $peptide_number_threshold=$ARGV[3];} else { $peptide_number_threshold=1; }
if ($ARGV[4]=~/\w/) { $fdr_peptide_threshold=$ARGV[4];} else { $fdr_peptide_threshold=0.01; }
if ($ARGV[5]=~/\w/) { $fdr_protein_threshold=$ARGV[5];} else { $fdr_protein_threshold=0.01; }
if ($ARGV[6]=~/\w/) { $msgf_threshold=$ARGV[6];} else { $msgf_threshold=1; }
if ($ARGV[7]=~/\w/) { $mascot_threshold=$ARGV[7];} else { $mascot_threshold=1; }
if ($ARGV[8]=~/\w/) { $filter=$ARGV[8];} else { $filter=""; }

if ($error==0)
{
	$textfile=~s/\\/\//g;
	my $dir=$textfile;
	if ($dir!~s/\/[^\/]+$//) { $dir="."; }
	my $dir_=$dir;
	$dir_=~s/\//\\/g;
	my $textfile_=$textfile;
	$textfile_=~s/\.txt//g;	
	open (LOG,qq!>$textfile_.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.log!) || die "Could not open output $textfile_.log\n";
	my %mapping_found=();
	my %mapping=();
	my $line="";
	my $started=0;
	my %index=();
	my %sample_categories=();
	my %pep_all=();
	my %pep_all_proteins=();
	my %pep_all_proteins_count=();
	my %pepmod=();
	my %peptides=();
	my %scores_peptide=();
	my %scores=();
	my %scores_rev=();
	my %msgf=();
	my %msgf_rev=();
	my %peptide_spectrum_count=();
	my %pepmod_proteins=();
	my %pepmod_proteins_count=();
	my %peptide_proteins=();
	my %peptide_proteins_count=();
	my %protein_peptides=();
	my %protein_peptides_count=();
	open (IN,qq!$textfile_mapping_human!) || die "Could not open input $textfile_mapping_human\n";
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)$/)
		{
			my $pep=$1;
			my $prot=$2;
			my $pos=$3;
			$prot=~s/\|/___/g;
			$mapping{"human#$pep"}.="#$prot ($pos)#";
		}
		else { if ($line=~/\w/) { print qq!Error parsing: $line ($textfile_mapping_human)\n!; } }
		chomp($line);
	}
	close(IN);
	open (IN,qq!$textfile_mapping_mouse!) || die "Could not open input $textfile_mapping_mouse\n";
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)$/)
		{
			my $pep=$1;
			my $prot=$2;
			my $pos=$3;
			$prot=~s/\|/___/g;
			$mapping{"mouse#$pep"}.="#$prot ($pos)#";
		}
		else { if ($line=~/\w/) { print qq!Error parsing: $line ($textfile_mapping_mouse)\n!; } }
		chomp($line);
	}
	close(IN);
	
	open (IN,qq!$textfile!) || die "Could not open input $textfile\n";
								
	while ($line=<IN> and $error==0)
	{
		chomp($line);
		if ($started==1 and $line=~/\w/ and $line!~/END OF FILE/)
		{
			my $count=1;
			my @values=();
			$line.="\t";
			while($line=~s/^([^\t]*)\t//)
			{
				$values[$count]=$1;
				$values[$count]=~s/^\"//;
				$values[$count]=~s/\"$//;
				$count++;
			}
			my $mascot_score = $values[$index{"Mascot Ion score"}];
			my $proteins = $values[$index{"Protein accession numbers"}];
			my $pep = uc($values[$index{"Peptide sequence"}]);
			my $mod = $values[$index{"Variable modifications identified by spectrum"}];
			my $spectrum_name = $values[$index{"MS/MS sample name"}];
			my $sample_category=$spectrum_name;
			$sample_category=~s/^([^_]+_[^_]+).*$/$1/;
			$sample_category.=qq!-$values[$index{"Biological sample category"}]!;
			$sample_category=~s/\s+//g;
			if ($filter!~/\w/ or $spectrum_name=~/$filter/)
			{
				$pep=~tr/L/I/;
				$pep_all{"$pep"}=1;
				$pepmod{"$pep#$mod"}=1;
				$peptide_spectrum_count{"$sample_category#$pep"}++;
				$sample_categories{$sample_category}=1;
				if ($mapping{"human#$pep"}=~/\w/ or $mapping{"mouse#$pep"}=~/\w/) { $mapping_found{$pep}=1; }
				$proteins.=",";
				#print qq!-----$pep#$mod: $proteins\n!;
				while ($proteins=~s/^([^\,]+)\,//)
				{
					my $protein=$1;
					my $protein_=$protein;
					$protein=~s/\|/___/g;
					if ($pep_all_proteins{"$pep"}!~/#$protein#/) 
					{ 
						$pep_all_proteins{"$pep"}.="#$protein#";
						$pep_all_proteins_count{"$pep"}++;
					}
					if ($pepmod_proteins{"$pep#$mod"}!~/#$protein#/) 
					{ 
						$pepmod_proteins{"$pep#$mod"}.="#$protein#";
						$pepmod_proteins_count{"$pep#$mod"}++;
						#print qq!$pep#$mod: $pepmod_proteins{"$pep#$mod"}\n!;
					}
					if ($scores_peptide{"$pep"}<$mascot_score or $scores_peptide{"$pep"}!~/\w/) { $scores_peptide{"$pep"}=$mascot_score; }
					if ($protein!~/\-R$/)
					{
						if ($scores{"$pep#$mod"}<$mascot_score or $scores{"$pep#$mod"}!~/\w/) { $scores{"$pep#$mod"}=$mascot_score; }
						if ($index{"MSGF"})
						{
							my $msgf = $values[$index{"MSGF"}];
							if ($msgf=~/\w/)
							{
								if ($msgf{"$pep#$mod"}>$msgf or $msgf{"$pep#$mod"}!~/\w/) { $msgf{"$pep#$mod"}=$msgf; }
							}
						}
					}
					else
					{
						if ($scores_rev{"$pep#$mod"}<$mascot_score or $scores_rev{"$pep#$mod"}!~/\w/) { $scores_rev{"$pep#$mod"}=$mascot_score; }
						if ($index{"MSGF"})
						{
							my $msgf = $values[$index{"MSGF"}];
							if ($msgf=~/\w/)
							{
								if ($msgf_rev{"$pep#$mod"}>$msgf or $msgf_rev{"$pep#$mod"}!~/\w/) { $msgf_rev{"$pep#$mod"}=$msgf; }
							}
						}
					}
				}
			}
		}
		if ($line=~/^Experiment name\tBiological sample category\tBiological sample name/) 
		{ 
			my $count=1;
			$line.="\t";
			while($line=~s/^([^\t]+)\t//)
			{
				my $name=$1;
				$name=~s/^\"//;
				$name=~s/\"$//;
				$index{$name}=$count;
				$count++;
			}				
			if ($index{"Biological sample category"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Biological sample category' not found\n!; }
			if ($index{"MS/MS sample name"}!~/\w/) { $error=1; print LOG qq!Error: Column 'MS/MS sample name' not found\n!; }
			if ($index{"Spectrum name"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Spectrum name' not found\n!; }
			if ($index{"Protein accession numbers"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Protein accession numbers' not found\n!; }
			if ($index{"Peptide sequence"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Peptide sequence' not found\n!; }
			if ($index{"Mascot Ion score"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Mascot Ion score' not found\n!; }
			if ($index{"Variable modifications identified by spectrum"}!~/\w/) { $error=1; print qq!Error: Column 'Variable modifications identified by spectrum' not found\n!; }
			if ($index{"Spectrum charge"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Spectrum charge' not found\n!; }
			$started=1;
		}
	}
	close(IN);
	
	open (OUT_PEP,qq!>$textfile_.peptide_list.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.out!) || die "Could not open output $textfile_.out\n";
	print OUT_PEP qq!Peptide!;
	foreach my $sample_category (keys %sample_categories)
	{
		print OUT_PEP qq!\tSpectrum count $sample_category!;
	}
	print OUT_PEP qq!\tType (Human/Mouse/Shared)\tHuman proteins (position)\tMouse proteins (position)\n!;

	my @to_sort=();
	my $count_pep=0;
	foreach my $key (keys %pepmod)
	{
		if ($scores{$key}=~/\w/)
		{
			if ($msgf{"$key"}<=$msgf_threshold and $scores{"$key"}>=$mascot_threshold)
			{
				$to_sort[$count_pep++]=qq!$scores{$key}#$key#T!;
			}
		}
		else
		{
			if ($scores_rev{$key}=~/\w/)
			{
				if ($msgf_rev{"$key"}<=$msgf_threshold and $scores_rev{"$key"}>=$mascot_threshold)
				{
					$to_sort[$count_pep++]=qq!$scores_rev{$key}#$key#F!;
				}
			}
		}
	}
	my $score_peptide_last=0;
	my $fdr_peptide=0;
	my $fdr_peptide_last=0;
	my $count_T_peptide=0;
	my $count_F_peptide=0;
	my @sorted = sort { $b <=> $a } @to_sort;
	for(my $i=0;$i<$count_pep;$i++)
	{
		if ($sorted[$i]=~/^([^#]+)#([^#]+)#([^#]*)#([^#]+)$/)
		{
			my $score=$1;
			my $pep=$2;
			my $mod=$3;
			my $TF=$4;
			if ($TF=~/^T$/)
			{
				$count_T_peptide++;
			}
			else
			{
				$count_F_peptide++;
			}
			if ($count_T_peptide>0)
			{
				$fdr_peptide=$count_F_peptide/$count_T_peptide;
				print LOG qq!$score\t$count_T_peptide\t$count_F_peptide\t$fdr_peptide\n!;
				if ($fdr_peptide<=$fdr_peptide_threshold)
				{
					$fdr_peptide_last=$fdr_peptide;
					$score_peptide_last=$score;
					$peptides{$pep}=1;
					#my $proteins=$pepmod_proteins{"$pep#$mod"};
					my $proteins=$pep_all_proteins{"$pep"};
					if ($proteins!~/\w/) { $proteins=$pepmod_proteins{"$pep#$mod"}; }
					while ($proteins=~s/^#([^#]+)#//)
					{
						my $protein=$1;
						if ($peptide_proteins{"$pep"}!~/#$protein#/) 
						{ 
							$peptide_proteins{"$pep"}.="#$protein#";
							$peptide_proteins_count{"$pep"}++;
						}
						if ($protein_peptides{"$protein"}!~/#$pep#/) 
						{ 
							$protein_peptides{"$protein"}.="#$pep#";
							$protein_peptides_count{"$protein"}++;
						}
					}
				}
			}
		}
	}
	
	my @proteins_to_sort=();
	my $proteins_to_sort_count=0;
	foreach my $name (keys %protein_peptides_count)
	{
		if ($protein_peptides_count{$name}>0) 
		{
			$proteins_to_sort[$proteins_to_sort_count]=qq!$protein_peptides_count{$name}#$name!;
			$proteins_to_sort_count++;
		}
	}
	my @proteins_sorted = sort { $b <=> $a } @proteins_to_sort;
	my $proteins_sorted_count=0;
	my %protein_peptides_unique_count=();
	my $proteins_unique_count=0;
	my %peptides_done=();
	my %protein_score=();
	my %protein_spectrum_count=();
	my $fdr_protein=0;
	my $fdr_protein_last=0;
	my $count_T_protein=0;
	my $count_F_protein=0;
	open(OUT,">$textfile_.count_proteins.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.txt");
	print OUT qq!protein\tpeptides!;
	foreach my $sample_category (keys %sample_categories)
	{
		print OUT qq!\tSpectrum count $sample_category!;
	}
	print OUT qq!\tfdr\tType (Human/Mouse/Shared)\tHuman peptides\tMouse peptides\tShared peptides\n!;
	open(OUT_ALL,">$textfile_.count_proteins.all.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.txt");
	print OUT_ALL qq!protein\tpeptides\tpeptides_unique\n!;
	for($proteins_sorted_count=0;$proteins_sorted_count<$proteins_to_sort_count;$proteins_sorted_count++)
	{
		if ($proteins_sorted[$proteins_sorted_count]=~/#([^#]+)$/)
		{
			my $name=$1;
			$protein_peptides_unique_count{$name}=0;
			my $temp=$protein_peptides{$name};
			my %peptides_done_this=();
			while($temp=~s/^#([^#]+)#//)
			{
				my $pep=$1;
				if ($peptides_done_this{$pep}!~/\w/)
				{
					$peptides_done_this{$pep}=1;
					foreach my $sample_category (keys %sample_categories)
					{
						$protein_spectrum_count{"$sample_category#$name"}+=$peptide_spectrum_count{"$sample_category#$pep"};
					}
				}
				$protein_score{$name}+=$scores_peptide{$pep};
				if ($peptides_done{$pep}!~/\w/)
				{
					$peptides_done{$pep}=1;
					$protein_peptides_unique_count{$name}++;
				}
			}
			my $name_original=$name;
			$name_original=~s/___/\|/g;
			print OUT_ALL qq!$name_original\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\n!;
		}
	}
	
	#@proteins_to_sort=();
	#$proteins_to_sort_count=0;
	#foreach my $name (keys %protein_peptides_count)
	#{
	#	if ($protein_peptides_unique_count{$name}>0) 
	#	{
	#		$proteins_to_sort[$proteins_to_sort_count]=qq!$protein_score{$name}#$name!;
	#		$proteins_to_sort_count++;
	#	}
	#}
	#@proteins_sorted = sort { $b <=> $a } @proteins_to_sort;
	%peptides_done=();
	for($proteins_sorted_count=0;$proteins_sorted_count<$proteins_to_sort_count;$proteins_sorted_count++)
	{
		if ($proteins_sorted[$proteins_sorted_count]=~/#([^#]+)$/)
		{
			my $name=$1;
			if ($protein_peptides_unique_count{$name}>0)
			{
				if ($name!~/\-R$/) 
				{ 
					$count_T_protein++; 
					$fdr_protein=$count_F_protein/$count_T_protein;
					#print qq!$count_F_protein/$count_T_protein=$fdr_protein\n!;
					if ($fdr_protein<=$fdr_protein_threshold and $protein_peptides_count{$name}>=$peptide_number_threshold)
					{
						$fdr_protein_last=$fdr_protein;
						my $temp=$protein_peptides{$name};
						my $human_count=0;
						my $mouse_count=0;
						my $shared_count=0;
						while($temp=~s/^#([^#]+)#//)
						{
							my $pep=$1;
							my $type="";
							my $human_proteins=$mapping{"human#$pep"};
							my $mouse_proteins=$mapping{"mouse#$pep"};
							if ($human_proteins=~/\w/ and $mouse_proteins=~/\w/)
							{
								$type="S";
								$shared_count++;
							}
							else
							{
								if ($human_proteins=~/\w/)
								{
									$type="H";
									$human_count++;
								}
								if ($mouse_proteins=~/\w/)
								{
									$type="M";
									$mouse_count++;
								}
							}
							$human_proteins=~s/___/\|/g;
							$mouse_proteins=~s/___/\|/g;
							$human_proteins=~s/##/, /g;
							$mouse_proteins=~s/##/, /g;
							$human_proteins=~s/#//g;
							$mouse_proteins=~s/#//g;
							if ($peptides_done{$pep}!~/\w/)
							{
								$peptides_done{$pep}=1;
								print OUT_PEP qq!$pep!;
								foreach my $sample_category (keys %sample_categories)
								{
									print OUT_PEP qq!\t$peptide_spectrum_count{"$sample_category#$pep"}!;
								}
								print OUT_PEP qq!\t$type\t$human_proteins\t$mouse_proteins\n!;
							}
						}
						my $name_original=$name;
						$name_original=~s/___/\|/g;
						my $type="";
						if ($human_count+$mouse_count+$shared_count==$protein_peptides_count{$name} or ($human_count+$mouse_count+$shared_count>$protein_peptides_count{$name}/3 and $human_count+$mouse_count+$shared_count>1))
						{
							if ($human_count>0 and $mouse_count>0) 
							{
								if ($human_count<$mouse_count) { $type="M"; } else { $type="H"; }
								print LOG qq!Strange ($name): both unique mouse ($mouse_count) and human ($human_count) peptides (shared: $shared_count)\n!; 
							}
							if ($human_count>0)
							{
								$type="H";
							}
							else
							{
								if ($mouse_count>0)
								{
									$type="M";
								}
								else 
								{ 
									if ($shared_count>0)
									{
										$type="S"; 
									}
								}
							}
						}
						else
						{
							print LOG qq!Other ($name): $human_count+$mouse_count+$shared_count<$protein_peptides_count{$name}\n!; 
							$type="O";
						}
						print OUT qq!$name_original\t$protein_peptides_count{$name}!;
						foreach my $sample_category (keys %sample_categories)
						{
							print OUT qq!\t$protein_spectrum_count{"$sample_category#$name"}!;
						}
						print OUT qq!\t$fdr_protein\t$type\t$human_count\t$mouse_count\t$shared_count\n!;
						$proteins_unique_count++;
					}
				} else { $count_F_protein++; }
			}
		}
	}
	close(OUT_PEP);
	close(OUT_ALL);
	close(OUT);
	
	my $pep_count=0;
	my %spec_count=();
	foreach my $pep (keys %peptides)
	{
		if ($mapping_found{$pep}!=1 and $pep_all_proteins{"$pep"}!~/\-R#/ and $pep_all_proteins{"$pep"}!~/#sp_/) { print LOG qq!Peptide $pep not found ($pep_all_proteins{"$pep"})\n!; }	
		foreach my $sample_category (keys %sample_categories)
		{
			$spec_count{$sample_category}+=$peptide_spectrum_count{"$sample_category#$pep"};
		}
		$pep_count++;
	}
	#foreach my $pep (keys %pep_all)
	#{
	#	if ($mapping_found{$pep}!=1 and $pep_all_proteins{"$pep"}!~/\-R#/ and $pep_all_proteins{"$pep"}!~/#sp_/) { print LOG qq!Peptide $pep not found ($pep_all_proteins{"$pep"})\n!; }	
	#}
	close(LOG);
	print qq!\n$proteins_unique_count proteins, $pep_count peptides, !; 
	foreach my $sample_category (keys %sample_categories)
	{
		print qq! $spec_count{$sample_category}($sample_category)!; 
	}
	print qq!spectra , FDR(protein)=$fdr_protein_last, FDR(peptide)=$fdr_peptide_last ($score_peptide_last)\n!; 
}