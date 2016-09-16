#!c:/perl/bin/perl.exe
# This program compares peptide sequences in mgf file with the corresponding 
# sequences in xml file below a particular expectation threshold. 
#
my $MGFfilename="";
my $filename="";
my $error=0;
my $id=""; 
my $count=0;
my $expect=0;
my $pep="";
my $threshold=0;
my %peptides=();
my %sequence=();

my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $method=$ARGV[1];} else { $method="2.2e-002"; }
$Filename=$filename;
$Filename=~s/\.xml//g;
open (OUT,">$Filename.txt") || die "Could not open output file\n";

if($method=~/^(\S+)$/) { $threshold=$1; }
else {	$threshold=1e-3; }

if ($error==0)
{
	open (IN,"$filename") || die "Could not open xml file\n";
	while ($line=<IN>)
	{
		if ($line=~/\<note type=\"input\" label=\"spectrum\, path\"\>(.*)\<\/note\>/)
		{
			$MGFfilename=$1; 
		}
	}
	close(IN);
	open (IN,"$filename") || die "Could not open xml file\n";
	while ($line=<IN>)
	{
		if ($line=~/^\<\/domain\>/)
		{
			$expect=0;
			$pep="";
			$id="";
		}
		if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*seq="([A-Za-z]+)"/)
		{
			$id=$1;
			$expect=$2;
			$pep=$3;
			if ($expect < $threshold)
			{
				$peptides{$pep}=1;
			}
		}
		my $title="";
		open (IN1, "$MGFfilename") || die "Could not open mgf file\n";
		while ($line1=<IN1>)
		{
			if ($line1=~/^TITLE=([A-Za-z]+),/)
			{
				$title=$1; 
				if($peptides{$title}=~/\w/) { $sequence{$title}=1; }
				else { $sequence{$title}=0; }
			}
		}
		close(IN1);		
	}
	close(IN);
}
foreach my $seq(keys %sequence)
{
	print OUT qq!$seq\t$sequence{$seq}\n!;
}
close(OUT);