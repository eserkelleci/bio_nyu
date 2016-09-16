#!c:/perl/bin/perl.exe
#
#

$error=0;
$proton_mass=1.007276;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $threshold=$ARGV[1];} else { $threshold=1e-3; }
if ($ARGV[2]=~/\w/) { $mass_error=$ARGV[2];} else { $mass_error=20; }

$peptide_filename=$filename;
$peptide_filename=~s/\.xml$/.processed.txt/i;

if ($error==0)
{
	open (IN,"$filename") || die "Could not open $filename\n";
	$reversed=0;
	while ($line=<IN>)
	{
		if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
		{
			$protein_name=$1;
			if ($protein_name=~/\:reversed$/) { $reversed=1; } else { $reversed=0; }
		}
		if ($line=~/^\<\/protein\>/)
		{
			$protein_name="";
			$reversed=0;
		}
		if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
		{
			$id=$1;
			$expect=$2;
			$mh=$3;
			$delta=$4;
			$pep=$5;
			$id_=$id;
			$id_=~s/([0-9]+)\..*$/$1/;
			$mcalc=$mh-$proton_mass;
			$mexp=$mcalc+$delta;
			if ($expect<=$threshold)
			{
				if ($reversed==0)
				{
					$temp=$mcalc;
					$temp=~s/\..*$//;
					$peptides_unique{"$pep#$temp"}=$mcalc;
				}
				else
				{
				}
			}
		}
		if($line=~/<note label=\"Description\">(.+?)<\/note>/g)	
		{
		}
	}
	close(IN);

	open (OUT,">$peptide_filename") || die "Could not open $peptide_filename\n";
	foreach $pep_mass (sort keys %peptides_unique)
	{
		if($pep_mass=~/^([^#]+)#([^#]+)$/)
		{
			$pep=$1;
			$mass_nominal=$2;
			for($k=1;$k<=4;$k++)
			{
				$mz=$peptides_unique{$pep_mass}/$k + $proton_mass;
				for($j=0;$j<=3;$j++)
				{
					$mz_=$mz+($j-1)*1.007276/$k;
					$mz_min=$mz_*(1-$mass_error/1e+6);
					$mz_max=$mz_*(1+$mass_error/1e+6);
					print OUT "$pep\t$mass_nominal\t$k\t$mz_\t500\t$j\tP\t0\t1000000\t$mz_min\t$mz_max\n";
				}
			}
		}
	}
	close(OUT);


}

