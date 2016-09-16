#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $textfile="";
my $peptide_number_threshold="";
my $fdr_peptide_threshold="";
my $fdr_protein_threshold="";
my $msgf_threshold="";
my $mascot_threshold="";
my $filter="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $peptide_number_threshold=$ARGV[1];} else { $peptide_number_threshold=1; }
if ($ARGV[2]=~/\w/) { $fdr_peptide_threshold=$ARGV[2];} else { $fdr_peptide_threshold=0.01; }
if ($ARGV[3]=~/\w/) { $fdr_protein_threshold=$ARGV[3];} else { $fdr_protein_threshold=0.01; }
if ($ARGV[4]=~/\w/) { $msgf_threshold=$ARGV[4];} else { $msgf_threshold=1; }
if ($ARGV[5]=~/\w/) { $mascot_threshold=$ARGV[5];} else { $mascot_threshold=1; }
if ($ARGV[6]=~/\w/) { $filter=$ARGV[6];} else { $filter=""; }

if ($error==0)
{
	$textfile=~s/\\/\//g;
	my $dir=$textfile;
	if ($dir!~s/\/[^\/]+$//) { $dir="."; }
	my $dir_=$dir;
	$dir_=~s/\//\\/g;
	open (IN,qq!$textfile!) || die "Could not open input $textfile\n";
	my $textfile_=$textfile;
	$textfile_=~s/\.txt//g;
	open (OUT_PEP,qq!>$textfile_.peptide_list.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.out!) || die "Could not open output $textfile_.out\n";
	open (LOG,qq!>$textfile_.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.log!) || die "Could not open output $textfile_.log\n";
	my $line="";
	my $started=0;
	my %index=();
	my %pepmod=();
	my %protein_original=();
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
			if ($filter!~/\w/ or $spectrum_name=~/$filter/)
			{
				$pep=~tr/L/I/;
				$pepmod{"$pep#$mod"}=1;
				$peptide_spectrum_count{"$pep"}++;
				$proteins.=",";
				#print qq!-----$pep#$mod: $proteins\n!;
				while ($proteins=~s/^([^\,]+)\,//)
				{
					my $protein=$1;
					my $protein_=$protein;
					$protein=~s/\|/_/g;
					$protein_original{$protein}=$protein_;
					#print qq!###$protein $pepmod_proteins{"$pep#$mod"}\n!;
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
					my $proteins=$pepmod_proteins{"$pep#$mod"};
					while ($proteins=~s/^#([^#]+)#//)
					{
						my $protein=$1;
						if ($peptide_proteins{"$pep"}!~/#$protein#/) 
						{ 
							$peptide_proteins{"$pep"}.="#$protein#";
							$peptide_proteins_count{"$pep"}++;
						}
						if ($protein_peptides{"$protein"}!~/#$pep#"/) 
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
	print OUT qq!protein\tpeptides\tpeptides_unique\tspectrum_count\tfdr\n!;
	open(OUT_ALL,">$textfile_.count_proteins.all.$peptide_number_threshold.$fdr_peptide_threshold.$fdr_protein_threshold.$msgf_threshold.$mascot_threshold.txt");
	print OUT_ALL qq!protein\tpeptides\tpeptides_unique\tspectrum_count\n!;
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
					$protein_spectrum_count{$name}+=$peptide_spectrum_count{$pep};
				}
				$protein_score{$name}+=$scores_peptide{$pep};
				if ($peptides_done{$pep}!~/\w/)
				{
					$peptides_done{$pep}=1;
					$protein_peptides_unique_count{$name}++;
				}
			}
			print OUT_ALL qq!$protein_original{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\t$protein_spectrum_count{$name}\n!;
		}
	}
	
	@proteins_to_sort=();
	$proteins_to_sort_count=0;
	foreach my $name (keys %protein_peptides_count)
	{
		if ($protein_peptides_unique_count{$name}>0) 
		{
			$proteins_to_sort[$proteins_to_sort_count]=qq!$protein_score{$name}#$name!;
			$proteins_to_sort_count++;
		}
	}
	@proteins_sorted = sort { $b <=> $a } @proteins_to_sort;
	%peptides_done=();
	for($proteins_sorted_count=0;$proteins_sorted_count<$proteins_to_sort_count;$proteins_sorted_count++)
	{
		if ($proteins_sorted[$proteins_sorted_count]=~/#([^#]+)$/)
		{
			my $name=$1;
			if ($protein_peptides_unique_count{$name}>0)
			{
				if ($name!~/\-R$/) { $count_T_protein++; } else { $count_F_protein++; }
				if ($count_T_protein>0)
				{
					$fdr_protein=$count_F_protein/$count_T_protein;
					#print qq!$count_F_protein/$count_T_protein=$fdr_protein\n!;
					if ($fdr_protein<=$fdr_protein_threshold and $protein_peptides_count{$name}>=$peptide_number_threshold)
					{
						$fdr_protein_last=$fdr_protein;
						print OUT qq!$protein_original{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\t$protein_spectrum_count{$name}\t$fdr_protein\n!;
						$proteins_unique_count++;
						my $temp=$protein_peptides{$name};
						while($temp=~s/^#([^#]+)#//)
						{
							my $pep=$1;
							if ($peptides_done{$pep}!~/\w/)
							{
								$peptides_done{$pep}=1;
								print OUT_PEP qq!$pep\t$scores_peptide{$pep}\n!;
							}
						}
					}
				}
			}
		}
	}
	close(OUT_PEP);
	close(OUT_ALL);
	close(OUT);
	
	my $pep_count=0;
	my $spec_count=0;
	foreach my $pep (keys %peptides)
	{
		if ($peptides_done{$pep}!=1) { print LOG qq!Peptide $pep not found\n!; }
		
		$spec_count+=$peptide_spectrum_count{"$pep"};
		$pep_count++;
	}
	close(LOG);
	print qq!\n$proteins_unique_count proteins, $pep_count peptides, $spec_count spectra, FDR(protein)=$fdr_protein_last, FDR(peptide)=$fdr_peptide_last ($score_peptide_last)\n!; 
}