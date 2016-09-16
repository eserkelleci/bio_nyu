#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $xmlfile=0;
my $proton_mass=1.007276;
if ($ARGV[0]=~/\w/) { $xmlfile=$ARGV[0];} else { $error=1; }

if ($error==0)
{  
	#$xmlfile=~s/\\/\//g;
	my $line="";
	open (IN,qq!$xmlfile!) || die "Could not open $xmlfile\n";
	open (OUT,qq!>$xmlfile.basepeak.txt!) || die "Could not open $xmlfile\n";
	print OUT qq!scan\ttime\tpep\tmz\tproteins\n!;
	my $mh="";
	my $mz="";
	my $charge="";
	my $scan="";
	my $time="";
	my $proteins="";
	my $expect="";
	my $pep="";
	my $title="";
	while ($line=<IN>)
	{
		if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
		{
			my $protein_name=$1;
			if($protein_name!~/\:reversed$/) { $proteins.="#$protein_name#"; }
		}
		if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
		{
			$expect=$2;
			$pep=$5;
			$pep=~tr/L/I/;
		}
		if($line=~/<note label=\"Description\">(.+?)<\/note>/)	
		{
			$title=$1;
			if($title=~/Scan ([0-9]+), Time=([0-9\.\-\+]+).*/)
			{
				$scan=$1;
				$time=$2/60; 
			}
		}
		if($line=~/<GAML\:attribute type=\"M\+H\">(.*)<\/GAML\:attribute>/)
		{
			$mh=$1;		
		}
		if($line=~/<GAML:attribute type="charge">([0-9]+)<\/GAML:attribute>/)
		{
			$charge=$1;
			$mz=($mh+(($charge-1)*$proton_mass))/$charge; 
			if($expect<1e-1)
			{
				print OUT qq!$scan\t$time\t$pep\t$mz\t$proteins\n!;
			}
			$proteins="";
		}
	}	
	close(IN);
	close(OUT);	
	
	my $xmlfile_=$xmlfile;
	$xmlfile_=~s/\.xml$/.mgf/i;
	open (IN,qq!$xmlfile_!) || die "Could not open $xmlfile_\n";
	open (OUT,qq!>$xmlfile_.basepeak.txt!) || die "Could not open $xmlfile_.basepeak.txt\n";
	print OUT qq!scan\ttime\tcharge\tmz\t\n!;
	my $scan=0;
	my $time=0;
	my $charge=0;
	my $mz=0;
	while($line=<IN>)
	{
		chomp($line);
		if($line=~/BEGIN IONS/)
		{
			$scan=0;
			$time=0;
			$charge=0;
			$mz=0;
		}
		elsif($line=~/Scan\s+([0-9]+), Time=([0-9\.\-\+]+)/)
		{
			$scan=$1; 
			$time=$2/60;
			
		}
		elsif($line=~/CHARGE=(.*)/)
		{
			$charge=$1; 
		}
		elsif($line=~/PEPMASS=(.*)/)
		{
			$mz=$1; 
		}
		elsif($line=~/END IONS/)
		{
			print OUT qq!$scan\t$time\t$charge\t$mz\t\n!;
		}
	}
	close(IN);
	close(OUT);	

}