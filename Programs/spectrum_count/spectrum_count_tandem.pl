#!c:/perl/bin/perl.exe
#
#

$error=0;
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $threshold=$ARGV[1];} else { $threshold=1e-3; }

$peptide_filename_count=$filename;
$peptide_filename_count=~s/\.xml$/.$threshold.count.txt/i;
$peptide_rev_filename_count=$filename;
$peptide_rev_filename_count=~s/\.xml$/.$threshold.rev.count.txt/i;
$peptide_filename=$filename;
$peptide_filename=~s/\.xml$/.$threshold.txt/i;
$peptide_rev_filename=$filename;
$peptide_rev_filename=~s/\.xml$/.$threshold.rev.txt/i;

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
			$mcalc=$mh-1.007825;
			$mexp=$mcalc+$delta;
			if ($expect<=$threshold)
			{
				if ($reversed==0)
				{
					$peptides{$id_}="$pep\t$expect\t$mexp\t$mcalc\t$delta";
					$peptides_id{$id_}.="$id,";
				}
				else
				{
					$peptides_rev{$id_}="$pep\t$expect\t$mexp\t$mcalc\t$delta";
					$peptides_rev_id{$id_}.="$id,";
				}
			}
		}
		if($line=~/<note label=\"Description\">(.+?)<\/note>/g)	
		{
			$peptides_{$id_}=$1;
			$peptides_{$id_}=~s/^\s*CGItemp([0-9]+)\s*//;
		}
	}
	close(IN);
	foreach $id (keys %peptides)
	{
		$pep=$peptides{$id};
		$pep=~s/^([A-Z]+)\t.*$/$1/;
		$peptides_count{$pep}++;
	}	
	foreach $id (keys %peptides_rev)
	{
		$pep=$peptides_rev{$id};
		$pep=~s/^([A-Z]+)\t.*$/$1/;
		if ($peptides_count{$pep}!~/\w/)
		{
			$peptides_rev_count{$pep}++;
		}
	}
	
	open (OUT,">$peptide_filename") || die "Could not open $peptide_filename\n";
	print OUT "sequence\texpect\tmeasured\tcalculated\tdelta\ttitle\tids\n";
	foreach $id (sort keys %peptides)
	{
		$id_=$id;
		$id_=~s/([0-9]+)\..*$/$1/;
		print OUT "$peptides{$id}\t$peptides_{$id_}\t$peptides_id{$id_}\n";
	}
	close(OUT);
	
	open (OUT,">$peptide_rev_filename") || die "Could not open $peptide_rev_filename\n";
	print OUT "sequence\texpect\tmeasured\tcalculated\tdelta\ttitle\tids\n";
	foreach $id (sort keys %peptides_rev)
	{
		$id_=$id;
		$id_=~s/([0-9]+)\..*$/$1/;
		print OUT "$peptides_rev{$id}\t$peptides_{$id_}\t$peptides_rev_id{$id_}\n";
	}
	close(OUT);	
	
	open (OUT,">$peptide_filename_count") || die "Could not open $peptide_filename_count\n";
	print OUT "sequence\tcount\n";
	foreach $pep (sort keys %peptides_count)
	{
		print OUT "$pep\t$peptides_count{$pep}\n";
	}
	close(OUT);	
	
	open (OUT,">$peptide_rev_filename_count") || die "Could not open $peptide_rev_filename_count\n";
	print OUT "sequence\tcount\n";
	foreach $pep (sort keys %peptides_rev_count)
	{
		print OUT "$pep\t$peptides_rev_count{$pep}\n";
	}
	close(OUT);
}

