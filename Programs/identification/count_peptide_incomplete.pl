#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $textfile="";
my $mascot_threshold="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $mascot_threshold=$ARGV[1];} else { $mascot_threshold=0; }

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
	open (OUT_PEP,qq!>$textfile_.peptide_list.$mascot_threshold.out!) || die "Could not open output $textfile_.out\n";
	open (LOG,qq!>$textfile_.$mascot_threshold.log!) || die "Could not open output $textfile_.log\n";
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
			my $pep = uc($values[$index{"Peptide sequence"}]);
			my $sample_name=uc($values[$index{"MS/MS sample name"}]);
			if ($mascot_score>=$mascot_threshold)
			{
				$pep=~tr/L/I/;
				$sample_name=~s/\s.*$//;
				$peptide_spectrum_count{"$pep"}++;
				$peptide_spectrum_count{"$sample_name#$pep"}++;
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
			if ($index{"Peptide sequence"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Peptide sequence' not found\n!; }
			#if ($index{"Mascot Ion score"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Mascot Ion score' not found\n!; }
			$started=1;
		}
	}
	close(IN);
	my $incomplete_count=0;
	my $pep_count=0;
	my $incomplete_spectra=0;
	my $all_spectra=0;	
	my %incomplete_count=();
	my %pep_count=();
	my %incomplete_spectra=();
	my %all_spectra=();
	foreach my $key (keys %peptide_spectrum_count)
	{
		if ($key=~/^([^#]+)#(.+)$/)
		{
			my $name=$1;
			my $pep=$2;
			$name=~s/\s.*$//;
			if ($pep=~/[KR][^P]/) { $incomplete_count{$name}++; $incomplete_spectra{$name}+=$peptide_spectrum_count{"$key"}; }
			$pep_count{$name}++;
			$all_spectra{$name}+=$peptide_spectrum_count{"$key"};
		}
		else
		{
			my $pep=$key;
			#print qq!$pep\n!;
			if ($pep=~/[KR][^P]/) { $incomplete_count++; $incomplete_spectra+=$peptide_spectrum_count{"$key"}; }
			$pep_count++;
			$all_spectra+=$peptide_spectrum_count{"$key"};
		}
	}
	close(OUT);
	close(LOG);
	print qq!File\tincompletes\tincomplete spectra\tunique peptides\tspectra\n!;
	print qq!All\t$incomplete_count\t$incomplete_spectra\t$pep_count\t$all_spectra\n!;
	foreach my $name (sort keys %pep_count)
	{
		print qq!$name\t$incomplete_count{$name}\t$incomplete_spectra{$name}\t$pep_count{$name}\t$all_spectra{$name}\n!;
	}
}
