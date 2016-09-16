#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $dir="";
my $peptide_number_threshold="";
my $fdr_peptide_threshold="";
my $expect_threshold="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $peptide_number_threshold=$ARGV[1];} else { $peptide_number_threshold=1; }
if ($ARGV[2]=~/\w/) { $fdr_peptide_threshold=$ARGV[2];} else { $fdr_peptide_threshold=0.01; }
if ($ARGV[3]=~/\w/) { $expect_threshold=$ARGV[3];} else { $expect_threshold=1; }

if ($error==0)
{
	$dir=~s/\\/\//g;
	my $dir_=$dir;
	$dir_=~s/\//\\/g;
	open (OUT_PEP,qq!>$dir.peptide_list.$peptide_number_threshold.$fdr_peptide_threshold.$expect_threshold.out!) || die "Could not open output\n";
	open (LOG,qq!>$dir.$peptide_number_threshold.$fdr_peptide_threshold.$expect_threshold.log!) || die "Could not open output\n";
	my $line="";
	my %peptide_spectrum_count=();
	my %peptide_rev=();
	my %peptide_expect=();
	my %peptide_proteins_=();
	my %peptides=();
	my %peptide_proteins=();
	my %peptide_proteins_count=();
	my %protein_peptides=();
	my %protein_peptides_count=();
	my %protein_original=();

	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.xml$/i)
			{
				open (IN,"$dir/$filename") || die "Could not open $dir/$filename\n";
				my $reversed=1;
				my $pep="";
				my $expect="";
				my $proteins="";
				while ($line=<IN>)
				{
					if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
					{
						my $protein_name=$1;
						my $protein=$protein_name;
						$protein=~s/^(\S+)\s.*$/$1/;
						my $protein_=$protein;
						$protein=~s/\|/_/g;
						if ($protein_name!~/\:reversed$/) { $reversed=0; }
						$peptide_proteins_{$pep}.="#$protein#";
						$protein_original{$protein}=$protein_;
						#print qq!$protein_name#$protein#$protein_#\n!;
					}
					if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
					{
						my $expect_=$2;
						my $pep_=$5;
						$pep=~tr/L/I/;
						if ($expect!~/\w/ or $expect_<=$expect) { $expect=$expect_; $pep=$pep_; }
					}
					if($line=~/<note label=\"Description\">(.+?)<\/note>/)	
					{
						$pep=~tr/L/I/;
						$peptide_spectrum_count{$pep}++;
						$peptide_rev{$pep}=$reversed;
						$peptide_expect{$pep}=$expect;
						#print qq!#$pep#$expect#$reversed\n!;
						$reversed=1;
						$pep="";
						$expect="";
					}
				}			
			}
		}
	}
	close(IN);
	my @to_sort=();
	my $count_pep=0;
	foreach my $key (keys %peptide_spectrum_count)
	{
		if ($peptide_rev{$key}==0)
		{
			if ($peptide_expect{"$key"}<=$expect_threshold)
			{
				$to_sort[$count_pep++]=qq!$peptide_expect{$key}#$key#T!;
			}
		}
		else
		{
			if ($peptide_expect{"$key"}<=$expect_threshold)
			{
				$to_sort[$count_pep++]=qq!$peptide_expect{$key}#$key#F!;
			}
		}
	}
	my $expect_peptide_last=0;
	my $fdr_peptide=0;
	my $fdr_peptide_last=0;
	my $count_T_peptide=0;
	my $count_F_peptide=0;
	my @sorted = sort { $a <=> $b } @to_sort;
	for(my $i=0;$i<$count_pep;$i++)
	{
		if ($sorted[$i]=~/^([^#]+)#([^#]+)#([^#]+)$/)
		{
			my $expect=$1;
			my $pep=$2;
			my $TF=$3;
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
				print LOG qq!$expect\t$count_T_peptide\t$count_F_peptide\t$fdr_peptide\n!;
				if ($fdr_peptide<=$fdr_peptide_threshold)
				{
					$fdr_peptide_last=$fdr_peptide;
					$expect_peptide_last=$expect;
					if ($peptide_rev{$pep}==0)
					{
						$peptides{$pep}=1;
						my $proteins=$peptide_proteins_{"$pep"};
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
	open(OUT,">$dir.count_proteins.$peptide_number_threshold.$fdr_peptide_threshold.$expect_threshold.txt");
	print OUT qq!protein\tpeptides\tpeptides_unique\tspectrum_count\tfdr\n!;
	open(OUT_ALL,">$dir.count_proteins.all.$peptide_number_threshold.$fdr_peptide_threshold.$expect_threshold.txt");
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
				if ($peptide_rev{$pep}==0)
				{
					if ($peptides_done_this{$pep}!~/\w/)
					{
						$peptides_done_this{$pep}=1;
						$protein_spectrum_count{$name}+=$peptide_spectrum_count{$pep};
					}
					if ($peptides_done{$pep}!~/\w/)
					{
						$peptides_done{$pep}=1;
						$protein_peptides_unique_count{$name}++;
					}
				}
			}
			print OUT_ALL qq!$protein_original{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\t$protein_spectrum_count{$name}\n!;
			if ($protein_peptides_unique_count{$name}>0)
			{
				print OUT qq!$protein_original{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}\t$protein_spectrum_count{$name}\n!;
				$proteins_unique_count++;
			}
		}
	}
	
	
	my $pep_count=0;
	my $spec_count=0;
	foreach my $pep (keys %peptides)
	{
		if ($peptides_done{$pep}!=1) { print LOG qq!Peptide $pep not found\n!; }
		print OUT_PEP qq!$pep\t$peptide_spectrum_count{"$pep"}\t$peptide_expect{$pep}\n!;
		$spec_count+=$peptide_spectrum_count{"$pep"};
		$pep_count++;
	}
	close(LOG);
	close(OUT_PEP);
	close(OUT_ALL);
	close(OUT);
	print qq!$dir\t$proteins_unique_count proteins, $pep_count peptides, $spec_count spectra, FDR(protein)=$fdr_protein_last, FDR(peptide)=$fdr_peptide_last ($expect_peptide_last)\t$proteins_unique_count proteins\t$pep_count peptides\t$spec_count spectra\n!; 
}