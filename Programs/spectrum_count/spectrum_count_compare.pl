#!c:/perl/bin/perl.exe
#
#

$error=0;
if ($ARGV[0]=~/\w/) { $filename1=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $filename2=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $minimum=$ARGV[2];} else { $minimum=3; }

$filename_res=$filename2;
$filename_res=~s/\.txt$//i;
$filename_res=~s/^.*([\\\/])([\\\/]+)$/$1/g;
$filename_res="$filename1-$filename_res-$minimum";

if ($error==0)
{
	open (IN,"$filename1") || die "Could not open $filename1\n";
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)$/)
		{
			$pep=$1;
			$count=$2;
			$peptides1{$pep}=$count;
			$peptides{$pep}=1;
		}
	}
	close(IN);
	open (IN,"$filename2") || die "Could not open $filename1\n";
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([^\t]+)\t([^\t]+)$/)
		{
			$pep=$1;
			$count=$2;
			$peptides2{$pep}=$count;
			$peptides{$pep}=1;
		}
	}
	close(IN);
	
	open (OUT,">$filename_res.txt") || die "Could not open $filename_res.txt\n";
	print OUT qq!pep\t$filename1\t$filename2\n!;
	open (OUT_,">$filename_res.few.txt") || die "Could not open $filename_res.few.txt\n";
	print OUT_ qq!pep\t$filename1\t$filename2\n!;
	@RATIOS=();
	$count_ratios=0;
	foreach $pep (keys %peptides)
	{
		$temp1=$peptides1{$pep}; if ($temp1!~/\w/) { $temp1=0; }
		$temp2=$peptides2{$pep}; if ($temp2!~/\w/) { $temp2=0; }
		if ($peptides1{$pep}>=$minimum or $peptides2{$pep}>=$minimum)
		{
			print OUT qq!$pep\t$temp1\t$temp2\n!;
			if ($temp1<=0) { $temp1=0.00001; }
			if ($temp2<=0) { $temp2=0.00001; }
			$RATIOS[$count_ratios++]=log($temp1/$temp2)/log(2);
		}
		else
		{
			print OUT_ qq!$pep\t$temp1\t$temp2\n!;
		}
	}
	close(OUT);	
	close(OUT_);
	@RATIOS_SORTED = sort { $a <=> $b }@RATIOS;
	if ($count_ratios % 4) { $q1=$RATIOS_SORTED[int($count_ratios/4)]; } else { $q1=($RATIOS_SORTED[$count_ratios/4] + $RATIOS_SORTED[$count_ratios/4 - 1]) / 2; }
	if ($count_ratios % 2) { $median=$RATIOS_SORTED[int($count_ratios/2)]; } else { $median=($RATIOS_SORTED[$count_ratios/2] + $RATIOS_SORTED[$count_ratios/2 - 1]) / 2; }
	if ($count_ratios*3 % 4) { $q3=$RATIOS_SORTED[int($count_ratios*3/4)]; } else { $q3=($RATIOS_SORTED[$count_ratios*3/4] + $RATIOS_SORTED[$count_ratios*3/4 - 1]) / 2; }
	print qq!median = $median [$q1 - $q3]\n!;
}

