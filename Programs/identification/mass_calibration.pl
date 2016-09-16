#!c:/perl/bin/perl.exe
# This program plots a graph with calculated mass as X axis 
# and mass error in ppm as Y axis. Input is search XML file.
# A line is also fitted through the points to carry out
# mass caliberation.
#
use strict;

my $error=0;
my $MGFfilename="";
my $filename="";
my $calibrate="";
my $method="";
my $threshold=0;
my $line="";
my $scan="";
my %peptides=();
my %peptides_rev=();
my %peptides_rev_id=();
my %peptides_count=();
my %peptides_rev_count=();
my %peptides_=();
my %peptides_id=();
my $protein_name="";
my $id_="";
my $id=""; 
my @delta_corrected=();
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $method=$ARGV[1];} else { $method="1e-3 Yes"; }
if($method=~/^(\S+)\s(\S+)$/)
{
	$threshold=$1;
	$calibrate=$2;
}
else
{
	$threshold=1e-3;
	$calibrate="Yes";
}


my $peptide_filename=$filename;
$peptide_filename=~s/\.xml$/.$threshold/i;
my $peptide_rev_filename=$filename;
$peptide_rev_filename=~s/\.xml$/.$threshold.rev/i;
my $min_mass=10000000;
my $max_mass=0;
my $min_error=-100;
my $max_error=100;
my $min_scan=10000000;
my $max_scan=0;
my $error_units="ppm";
my $intercept=0;
my $rscan=0;
my $nscan=0;
my @deltapoints=();
my $points=0;
my @delta_sorted=();
my $lower_before=0;
my $upper_before=0;
my $lower_after=0;
my $upper_after=0;
my $delta=0;
my $delta_mass=0;
my $mh=0;
my $mcalc=0;
my $mexp=0;
my $expect=0;
my $pep=0;
if ($error==0)
{
	open (IN,"$filename") || die "Could not open $filename\n";
	my $reversed=0;
	while ($line=<IN>)
	{										
		if ($line=~/\<note type=\"input\" label=\"spectrum\, path\"\>(.*)\<\/note>/)
		{
			$MGFfilename=$1;
		}
		if ($line=~/<note type=\"input\" label=\"spectrum, parent monoisotopic mass error minus\">([0-9\.]+)<\/note>/)
		{
			$min_error="-$1";
		}
		if ($line=~/<note type=\"input\" label=\"spectrum, parent monoisotopic mass error plus\">([0-9\.]+)<\/note>/)
		{
			$max_error="$1";
		}
		if ($line=~/<note type=\"input\" label=\"spectrum, parent monoisotopic mass error units\">([A-Za-z]+)<\/note>/)
		{
			$error_units="$1";
		}
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
			if ($min_mass>$mcalc) { $min_mass=$mcalc; }
			if ($max_mass<$mcalc) { $max_mass=$mcalc; }
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
	my $print=0; 
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
	
	open (OUT,">$peptide_filename.txt") || die "Could not open $peptide_filename.txt\n";
	print OUT "sequence\texpect\tmeasured\tcalculated\tdelta\tscan\ttitle\tids\n";
	foreach $id (sort keys %peptides)
	{
		$id_=$id;
		$id_=~s/([0-9]+)\..*$/$1/;
		$scan=0;
		if ($peptides_{$id_}=~/scan\s+([0-9]+)/i) 
		{ 
			$scan=$1;
			if ($min_scan>$scan) { $min_scan=$scan; }
			if ($max_scan<$scan) { $max_scan=$scan; }
		}
		if ($peptides{$id_}=~/\t([^\t]+)\t([^\t]+)$/)
		{
			$mcalc=$1;
			$delta=$2;
			$print=0;
			if ($error_units=~/^ppm$/)
			{
				if ($min_error<=$delta/$mcalc*1e+6 and $delta/$mcalc*1e+6<=$max_error) 
				{ 
					$deltapoints[$points]=$delta/$mcalc*1e+6;
					$points++;
					$print=1;
				}
			}
			else
			{
				if ($min_error<=$delta and $delta<=$max_error) 
				{ 
					$deltapoints[$points]=$delta;
					$points++;
					$print=1;
				}
			}
			if ($print==1)
			{
				print OUT "$peptides{$id}\t$scan\t$peptides_{$id_}\t$peptides_id{$id_}\n";
			}
		}
	}
	close(OUT);

	if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=11)
							par(tcl=0.2)
							par(mfrow=c(2,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$peptide_filename.txt", header=TRUE, sep="\t")
							attach(Datafile)
							
				!;
				if ($error_units=~/^ppm$/)
				{
					print OUT2 qq!
							# plot(((delta/calculated)* 1e+6) ~ calculated, data=Datafile, ylim=c($min_error,$max_error), pch=20, cex=0.1, type="p", axes=TRUE, xlab="Calculated Mass", ylab="Mass Error")
							plot(measured ~ scan, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlab="Scan", ylab="Measured Mass")
							x <- c($min_scan,$max_scan)
							y <- c(0,0)
							lines(y ~ x, type="l")
							plot(((delta/calculated)* 1e+6) ~ scan, data=Datafile, ylim=c($min_error,$max_error), pch=20, cex=0.1, type="p", axes=TRUE, xlab="Scan", ylab="Mass Error")
							scanline.fit <- lm(((delta/calculated)* 1e+6) ~ scan)
							summary(scanline.fit)
							abline(scanline.fit, col = "red")
							# smoother curve
							loess.model2 <- loess(((delta/calculated)* 1e+6) ~ scan, span=0.75, degree=1)
							loess.model2
							predict2 <- predict(loess.model2)
							fit<-fitted.values(loess.model2)
							res<-residuals(loess.model2)
							fit
							res
							lines(scan[order(scan)], predict2[order(scan)], col="olivedrab")													
					!;
				}
				else
				{
					print OUT2 qq!
							# plot(delta ~ calculated, data=Datafile, ylim=c($min_error,$max_error), pch=20, cex=0.1, type="p", axes=TRUE, xlab="Calculated Mass", ylab="Mass Error")
							plot(measured ~ scan, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlab="Scan", ylab="Measured Mass")
							x <- c($min_scan,$max_scan)
							y <- c(0,0)
							lines(y ~ x, type="l")
							plot(delta ~ scan, data=Datafile, ylim=c($min_error,$max_error), pch=20, cex=0.1, type="p", axes=TRUE, xlab="Scan", ylab="Mass Error")
							scanline.fit <- lm(delta ~ scan)
							summary(scanline.fit)
							abline(scanline.fit, col = "red")
							# smoother curve
							loess.model2 <- loess(delta ~ scan, span=0.75, degree=1)
							loess.model2
							predict2 <- predict(loess.model2)
							fit<-fitted.values(loess.model2)
							res<-residuals(loess.model2)
							fit
							res
							lines(scan[order(scan)], predict2[order(scan)], col="olivedrab")
					!;
				}
				print OUT2 qq!
						x <- c($min_scan,$max_scan)
						y <- c(0,0)
						lines(y ~ x, type="l")
				!;
				
				print OUT2 qq!savePlot(filename="$peptide_filename.png",type="png")!;
				close(OUT2);
				system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				my $temp=$peptide_filename;
				$temp=~s/\//\\/g;
				system(qq!del "$temp.txt"!);
			}
	@delta_sorted = sort { $a <=> $b } @deltapoints;
	my $size = @delta_sorted;
	my $lower_range=(5/100)*$size;
	$lower_range=~s/\..*$//;
	$lower_before=$delta_sorted[$lower_range];
	my $upper_range=$size-$lower_range;
	$upper_range=~s/\..*$//;
	$upper_before=$delta_sorted[$upper_range];
	my $MGFfilename_=$MGFfilename;
	$MGFfilename_=~s/\.mgf$//i;
	my $line_="";
	open(OUT,">$MGFfilename_.cal");
	print OUT ">    fit\n";
	open (IN,"R-outfile.txt") || die "Could not open $filename\n";
	while ($line=<IN>)
	{
		if ($line=~/\(Intercept\)\s+([0-9\.\+\-edED]+)/i)
		{
			$intercept="$1";
		}
		if ($line=~/scan\s+([0-9\.\+\-edED]+)/i)
		{
			$rscan="$1";
		}
		if ($line=~/^\s*\[.*/i)
		{
			print OUT "$line";
		}
		if ($line=~/^\>\s*res$/i)
		{
			$line="res";
			$line_=$line;
			print OUT ">     res\n";
		}
		if ($line_ eq "res" and $line=~/^\s*([\+\-0-9\.\+\-edED]+).*/)
		{
			print OUT "$line";
		}
	}
	$size=0;
	foreach $id (sort keys %peptides)
	{
		$id_=$id;
		$id_=~s/([0-9]+)\..*$/$1/;
		$scan=0;
		if ($peptides_{$id_}=~/scan\s+([0-9]+)/i) 
		{ 
			$scan=$1;
			if ($peptides{$id_}=~/\t([^\t]+)\t([^\t]+)$/)
			{
				$mcalc=$1;
				$delta=$2;
				if ($error_units=~/^ppm$/)
				{
					if ($min_error<=$delta/$mcalc*1e+6 and $delta/$mcalc*1e+6<=$max_error) 
					{
						$delta_corrected[$size]=$delta/$mcalc*1e+6-($scan*$rscan+$intercept);
						$size++;
					}
				}
				else
				{
					if ($min_error<=$delta and $delta<=$max_error) 
					{
						$delta_corrected[$size]=$delta-($scan*$rscan+$intercept);
						$size++;
					}
				}
			}
		}
	}	
	@delta_sorted = sort { $a <=> $b } @delta_corrected;
	$size = @delta_sorted;
	$lower_range=(5/100)*$size;
	$lower_range=~s/\..*$//;
	$lower_after=$delta_sorted[$lower_range];
	$upper_range=$size-$lower_range;
	$upper_range=~s/\..*$//;
	$upper_after=$delta_sorted[$upper_range];
	close(IN);



	print OUT qq!\nIntercept=$intercept\nSlope=$rscan\n!;
	print OUT qq!Lower_before=$lower_before\nUpper_before=$upper_before\n!;
	print OUT qq!Lower_after=$lower_after\nUpper_after=$upper_after\n!;
	close(OUT);
		
	if ($calibrate=~/^Yes$/i)
	{	
		open (IN, "$MGFfilename");
		if(open (OUT,">$MGFfilename_.cal.mgf"))
		{
			my $oldpepmass=0;
			my $charge=0;
			my $oldscan=0;
			my $title="";
			my $line="";
			my $newscan=0;
			my $newpepmass=0;
			my $mz="";
			my $intensity="";
			while($line=<IN>)
			{	
				if($line=~/BEGIN IONS/)
				{
					print OUT "$line";
				}
				if ($line=~/^TITLE=(.*)$/)
				{
					$title=$1;
					print OUT "TITLE=$title\n";
				}
				if($line=~/Scan\s+([0-9]+)/)
				{
					$scan=$1;
					$delta_mass=$scan*$rscan+$intercept;
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
				{
					$oldpepmass=$1;
					if ($error_units=~/^ppm$/)
					{
						$newpepmass=$oldpepmass*(1-$delta_mass/1e+6);
					}
					else
					{
						$newpepmass=$oldpepmass-$delta_mass;
					}
					print OUT "PEPMASS=$newpepmass\n";
				}
				
				if ($line=~/^CHARGE=([0-9\.\-\+]+)\s*$/)
				{
					$charge=$1;
					print OUT "CHARGE=$charge\n";
				}
					
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
				{
					$mz=$1;
					$intensity=$2;
					print OUT "$mz\t$intensity\n";
				}
				if($line=~/END IONS/)
				{
					print OUT "$line\n";
				}			
				$oldpepmass="";
				$title="";
				$oldscan="";
				$newscan="";
				$newpepmass="";
				$mz="";
				$intensity="";
				$charge="";
			}	
			close(OUT);
		}
		close(IN);
	}
	system(qq!del R-outfile.txt!);
}
	