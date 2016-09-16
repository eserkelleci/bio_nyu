#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $textfile="";
my $name="";
my $spectrum_names="";
if ($ARGV[0]=~/\w/) { $textfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $name=$ARGV[1];} else { $name="WHIM2"; }
if ($ARGV[2]=~/\w/) { $spectrum_names=$ARGV[2];} else { $spectrum_names="Ellis_041_2781_261_01_cal,Ellis_041_2781_261_02_cal,Ellis_041_2781_261_03_cal,Ellis_041_2781_261_04_cal,Ellis_041_2781_261_05_cal,Ellis_041_2781_261_06_cal,Ellis_041_2781_261_07_cal"; }
#if ($ARGV[1]=~/\w/) { $name=$ARGV[1];} else { $name="WHIM16"; }
#if ($ARGV[2]=~/\w/) { $spectrum_names=$ARGV[2];} else { $spectrum_names="Ellis_041_2781_261_08_cal,Ellis_041_2781_261_09_cal,Ellis_041_2781_261_10_cal,Ellis_041_2781_261_11_cal,Ellis_041_2781_261_12_cal,Ellis_041_2781_261_13_cal,Ellis_041_2781_261_14_cal"; }

if ($error==0)
{
	$spectrum_names.=",";
	$textfile=~s/\\/\//g;
	my $dir=$textfile;
	if ($dir!~s/\/[^\/]+$//) { $dir="."; }
	my $dir_=$dir;
	$dir_=~s/\//\\/g;
	open (IN,qq!$textfile!) || die "Could not open input $textfile\n";
	my $textfile_=$textfile;
	$textfile_=~s/\.txt//g;
	open (OUT,qq!>$textfile_.$name.txt!) || die "Could not open output $textfile_.out\n";
	open (LOG,qq!>$textfile_.$name.log!) || die "Could not open output $textfile_.log\n";
	my $line="";
	my $started=0;
	my %index=();

	while ($line=<IN> and $error==0)
	{
		chomp($line);
		my $line_=$line;
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
			my $spectrum_name = $values[$index{"MS/MS sample name"}];
			$spectrum_name=~s/\s*\(.*$//;
			if ($spectrum_names=~/^$spectrum_name,/ or $spectrum_names=~/,$spectrum_name,/) 
			{ 
				print OUT qq!$line_\n!; 
			}
		} else { print OUT qq!$line_\n!; }
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
			if ($index{"MS/MS sample name"}!~/\w/) { $error=1; print LOG qq!Error: Column 'Spectrum name' not found\n!; }
			$started=1; 
		}
	}
	close(IN);
	close(OUT);
	close(LOG);
}