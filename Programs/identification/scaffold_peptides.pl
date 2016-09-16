#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $textfile="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; }

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
	open (OUT,qq!>$textfile_.peptide_list.out!) || die "Could not open output $textfile_.out\n";
	my $line="";
	my $started=0;
	my %index=();
	my %pep=();
	

	while ($line=<IN> and $error==0)
	{
		chomp($line);
		if ($started==1 and $line=~/\w/ and $line!~/END OF FILE/)
		{
			my $count=1;
			my @values=();
			while($line=~s/^([^\t]*)\t//)
			{
				$values[$count]=$1;
				$values[$count]=~s/^\"//;
				$values[$count]=~s/\"$//;
				$count++;
			}
			my $pep = uc($values[$index{"Peptide sequence"}]);
			$pep=~tr/L/I/;
			$pep{$pep}++;
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
			if ($index{"Peptide sequence"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Peptide sequence' not found\n!; }
			$started=1;
		}
	}
	close(IN);
	foreach my $pep (keys %pep)
	{
		print OUT qq!$pep\t$pep{$pep}\n!;
	}
	close(OUT);
}