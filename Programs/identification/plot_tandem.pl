#!c:/perl/bin/perl.exe
#
#

$error=0;
$proton_mass=1.007276;
$c12_13_mass_diff=1.0033548;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $threshold=$ARGV[1];} else { $threshold=1e-4; }
if ($ARGV[2]=~/\w/) { $mass_error=$ARGV[2];} else { $mass_error=20; }
if ($ARGV[3]=~/\w/) { $silac=$ARGV[3];} else { $silac="10.0083\@R,6.02013\@K"; }

$filename=~s/\\/\//g;
$dir=$filename;
if ($dir=~s/\/([^\/]+)$//) { ; } else { $dir=".";}

$peptide_filename=$filename;
$peptide_filename=~s/\.xml$/.processed.txt/i;

if ($error==0)
{
	%scans_ms2=();
	$scans_ms2_min=1000000000;
	$scans_ms2_max=0;
	open (IN,"$filename") || die "Could not open $filename\n";
	$MGFfilename="";
	$reversed=0;
	while ($line=<IN>)
	{
		if ($line=~/\<group.*z=\"([0-9]+)\"/)
		{
			$charge=$1;
		}
		if ($line=~/\<note type=\"input\" label=\"spectrum\, path\"\>(.*)\<\/note>/)
		{
			$MGFfilename=$1;
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
		if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*start="([0-9]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
		{
			$id=$1;
			$start=$2;
			$expect=$3;
			$mh=$4;
			$delta=$5;
			$pep=$6;
			$id_=$id;
			$id_=~s/([0-9]+)\..*$/$1/;
			$mcalc=$mh-$proton_mass;
			$mexp=$mcalc+$delta;
			if ($min_mass>$mcalc) { $min_mass=$mcalc; }
			if ($max_mass<$mcalc) { $max_mass=$mcalc; }
			$peptides_mod{$id_}="";
			if ($reversed==0)
			{
				$mod="";
				my $done=0;
				while($done==0)
				{
					$line=<IN>;
					if ($line=~/\<\/domain\>/) { $done=1; }
					else
					{
						if ($line=~/\<aa\s+type=\"[a-zA-Z+]\"\s+at=\"([0-9]+)\"\s+modified=\"([0-9\.\+\-]+)\"\s*/)
						{
							my $pos=$1-$start;
							my $mod_mass=$2;
							$mod.="$mod_mass\@$pos,";
						} else { $done=1; }
					}
				}
			}
		}
		if($line=~/<note label=\"Description\">(.+?)<\/note>/)	
		{
			my $description=$1;
			$description=~s/^\s*CGItemp([0-9]+)\s*//;
			if ($description=~/scan\s+([0-9]+)/i) 
			{ 
				$scan=$1;
				if ($expect<=$threshold)
				{
					if ($peptide_expect{"$pep#$mod#$charge"}!~/\w/ or $peptide_expect{"$pep#$mod#$charge"}<$expect)
					{
						$peptide_expect{"$pep#$mod#$charge"}=$expect;
						$peptide_mass{"$pep#$mod#$charge"}=$mexp;
						$peptide_scan{"$pep#$mod#$charge"}=$scan;
						$scans_ms2{$scan}=1;
						if ($scans_ms2_max<$scan) { $scans_ms2_max=$scan; }
						if ($scans_ms2_min>$scan) { $scans_ms2_min=$scan; }
					}
				}
			}
		}
	}
	close(IN);

	open (OUT,">$peptide_filename") || die "Could not open $peptide_filename\n";
	foreach $key (sort keys %peptide_mass)
	{
		if($key=~/^([^#]+)#([^#]*)#([^#]+)$/)
		{
			$pep=$1;
			$mod=$2;
			$charge=$3;
			$mz=$peptide_mass{"$pep#$mod#$charge"}/$charge+$proton_mass;
			@pep_mods=();
			$temp="$silac,";
			@silac_mods=();
			$silac_count=0;
			while($temp=~s/^([^\@]+)\@([^\,]+)\,//)
			{
				$silac_mod_mass=$1;
				$silac_mod_aa=$2;
				$temp_="$mod,";
				$pep_mod_count=0;
				while($temp_=~s/^([^\,]+)\,//)
				{
					$pep_mod=$1;
					if ($pep_mod=~/^$silac_mod_mass\@/)
					{
						$silac_mods[$silac_count]++;
						$mz-=$silac_mod_mass/$charge;
						$pep_mods[$pep_mod_count]=1;
					}
					else
					{
						$pep_mod_other.="$pep_mod,";
					}
					$pep_mod_count++;
				}
				$silac_count++;
			}
			print OUT qq!$pep\t$mod\t$charge!;
			$temp="$silac,";
			$silac_count=0;
			while($temp=~s/^([^\@]+)\@([^\,]+)\,//)
			{
				$silac_mod_mass=$1;
				$silac_mod_aa=$2;
				print OUT qq!\t$silac_mods[$silac_count]!;
				$silac_count++;
			}
			$temp_="$mod,";
			$pep_mod_count=0;
			$pep_mod_other="";
			while($temp_=~s/^([^\,]+)\,//)
			{
				$pep_mod=$1;
				if ($pep_mods[$pep_mod_count]!=1)
				{
					$pep_mod_other.=qq!$pep_mod,!;
				}
				$pep_mod_count++;
			}
			print OUT qq!\t$pep_mod_other\t$peptide_mass{$key}\n!;
			$unique_peptides_mass{"$pep#$pep_mod_other#$charge"}.="#$mz#";
			$unique_peptides_scan{"$pep#$pep_mod_other#$charge"}.=qq!#$peptide_scan{"$pep#$mod#$charge"}#!;
		}
	}
	close(OUT);
	
	@scans_ms1=();
	$scans_ms1_count=0;
	$MGFfilename=~s/^.*\/([^\/]+)$/$1/;
	$dir_=$MGFfilename;
	$dir_=~s/\.MS([0-9]+)\.([A-Z]+)\.MGF$//i;
	$dir_=~s/\.mzXML$//i;
	$dir_.=".dir";
	$MGFfilename=~s/\.MS([0-9]+)\.([A-Z]+)\.MGF$/.MS1.MGF/i;
	print qq!$dir/$MGFfilename\n!;
	if (opendir(dir,"$dir/$dir_"))
	{
		@allfiles = readdir dir;
		closedir dir;
		foreach $filename_ (@allfiles)
		{
			if ($filename_=~/\-([0-9]+)\.mgf/i)
			{
				$scan=$1;
				$scans_ms1[$scans_ms1_count++]=$scan;
			}
		}
	}
	else
	{
		mkdir(qq!$dir/$dir_!);

		if(open (IN, "$dir/$MGFfilename"))
		{
			my $min_mz=10000000;
			my $max_mz=0;
			my $max_intensity=0;
			my $title="";
			my $scan="";
			my @mz=();
			my @intensity=();
			my $header="";
			my $footer="";
			my $started_reading_fragments=0;
			my $done_reading_fragments=0;
			my $points=0;
			my $line="";
			while($line=<IN>)
			{
				if ($line=~/^TITLE=(.*)$/)
				{
					$title=$1;
					if ($title=~/scan\s+([0-9]+)/i) { $scan=$1; }
					#print qq!$scan\n!;
				}
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
				{
					$started_reading_fragments=1;
					$mz[$points]=$1;
					$intensity[$points]=$2;
					if ($min_mz>$mz[$points]) { $min_mz=$mz[$points]; }
					if ($max_mz<$mz[$points]) { $max_mz=$mz[$points]; }
					if ($max_intensity<$intensity[$points]) { $max_intensity=$intensity[$points]; }
					$points++;
				}
				else
				{
					if ($started_reading_fragments==1)
					{
						$done_reading_fragments=1;
					}
				}
				if ($started_reading_fragments==0)
				{
					$header.=$line;
				}
				else
				{
					if ($done_reading_fragments==1)
					{
						$footer.=$line;
						if ($scan=~/\w/)
						{
							if(open (OUT,">$dir/$dir_/$MGFfilename-$scan.mgf"))
							{
								print OUT $header;
								for(my $i=0;$i<$points;$i++)
								{
									print OUT "$mz[$i] $intensity[$i]\n";
								}
								print OUT $footer;
								close(OUT);
								$scans_ms1[$scans_ms1_count++]=$scan;
							}
						}
						$max_intensity=0;
						$title="";
						$scan="";
						@mz=();
						@intensity=();
						$header="";
						$footer="";
						$started_reading_fragments=0;
						$done_reading_fragments=0;
						$points=0;
						$count++;
					}
				}
			}
			close(IN);
		} 
	}
	@scans_ms1_sorted = sort { $a <=> $b } @scans_ms1;
	%scan_map=();
	$j=0;
	foreach $i (sort { $a <=> $b } keys %scans_ms2)
	{
		for(;$j<=$scans_ms1_count and $scans_ms1_sorted[$j]<$i;$j++) { ; }
		$j--;
		$scan_map{$i}="";
		for($k=$j-4;$k<=$j+4;$k++) { $scan_map{$i}.="$scans_ms1_sorted[$k] "; }
		#print "$i: $scan_map{$i}\n";
	}

	open (OUT,">$peptide_filename.txt") || die "Could not open $peptide_filename\n";
	%silac_mod=();
	$temp="$silac,";
	while($temp=~s/^([^\@]+)\@([^\,]+)\,//)
	{
		$silac_mod_mass=$1;
		$silac_mod_aa=$2;
		$silac_mod{$silac_mod_aa}=$silac_mod_mass;
	}
	foreach $key (sort keys %unique_peptides_mass)
	{
		if($key=~/^([^#]+)#([^#]*)#([^#]+)$/)
		{
			$pep=$1;
			$mod=$2;
			$charge=$3;
			$temp=$pep;
			$delta_mass=0;
			while($temp=~s/^([A-Z])//)
			{
				$aa=$1;
				if ($silac_mod{$aa}=~/\w/) { $delta_mass+=$silac_mod{$aa}; }
			}
			if ($delta_mass>0)
			{
				$mz=0;
				if($unique_peptides_mass{$key}=~/^#([^#]+)#$/)
				{
					$mz=$1;
				}
				$diff=0;
				if($unique_peptides_mass{$key}=~/^#([^#]+)##([^#]+)#$/)
				{
					$diff=1e+6*($2-$1)/$1;
				}
				$scan=0;
				if($unique_peptides_scan{$key}=~/^#([^#]+)#$/)
				{
					$scan=$1;
				}
				$scan_diff=0;
				if($unique_peptides_scan{$key}=~/^#([^#]+)##([^#]+)#$/)
				{
					$scan_diff=$2-$1;
				}
				if (abs($diff)<$mass_error and $scan>0 and $mz>0)
				{
					$plot_mz_min=$mz*(1-$mass_error/1e+6)-2/$charge;
					$plot_mz_max=$mz*(1+$mass_error/1e+6)+($delta_mass+5)/$charge;
					$plot_int_max=0;
					$temp=$scan_map{$scan};
					$message="";
					while($temp=~s/^(\S+)\s//)
					{
						$scan_=$1;
						if(open (IN,"$dir/$dir_/$MGFfilename-$scan_.mgf"))
						{
							if(open (OUT_,">$dir/$dir_/$pep-$mod-$charge-$scan_.txt"))
							{
								print OUT_ qq!mz\tint\n!;
								print OUT_ qq!$plot_mz_min\t0\n!;
								while($line=<IN>)
								{
									if ($line=~/^([0-9\.\-\+edED]+)\s+([0-9\.\-\+edED]+)$/)
									{
										$mz_=$1;
										$int_=$2;
										if ($plot_mz_min<=$mz_ and $mz_<=$plot_mz_max)
										{
											print OUT_ qq!$mz_\t$int_\n!;
											if (($mz*(1-$mass_error/1e+6)-0.5/$charge<=$mz_ and $mz_<=$mz*(1+$mass_error/1e+6)+3.5/$charge) or
												($mz*(1-$mass_error/1e+6)-0.5/$charge+$delta_mass/$charge<=$mz_ and $mz_<=$mz*(1+$mass_error/1e+6)+3.5/$charge+$delta_mass/$charge)
												)
											{
												if ($plot_int_max<$int_) { $plot_int_max=$int_; }
											}
										}
									}
								}
								print OUT_ qq!$plot_mz_max\t0\n!;
								close(OUT_);
							}
							close(IN);
						}
						else 
						{
							$message.="$dir/$dir_/$MGFfilename-$scan_.mgf, ";
						}
					}
					
					if(open(OUT2,qq!>R-infile.txt!))
					{
						print OUT2 qq!windows(width=8, height=11)
									par(tcl=0.2)
									par(mfrow=c(9,1))
									par(mai=c(0.0,0.0,0,0))
									par(font=1)
									y <- c(0,0)
						!;
						for($i=0;$i<=2;$i++)
						{
							$mz_=$mz+$i*$c12_13_mass_diff/$charge;
							print OUT2 qq!x$i <- c($mz_,$mz_)\n!;
						}
						for($i=0;$i<=2;$i++)
						{
							$mz_=$mz+($i*$c12_13_mass_diff+$delta_mass)/$charge;
							print OUT2 qq!x_$i <- c($mz_,$mz_)\n!;
						}
						$temp=$scan_map{$scan};
						$message="";
						$first=1;
						while($temp=~s/^(\S+)\s//)
						{
							$scan_=$1;
							$plot_mz_min_=int($plot_mz_min); 
							$plot_mz_max_=int($plot_mz_max+1); 
							$plot_int_max_log10=log($plot_int_max)/log(10); $plot_int_max_log10=~s/\.([0-9]).*$/.$1/;
							print OUT2 qq!Datafile$scan_ <- read.table("$dir/$dir_/$pep-$mod-$charge-$scan_.txt", header=TRUE, sep="\t")\n!;
							print OUT2 qq!plot(int ~ mz, data=Datafile$scan_, xlim=c($plot_mz_min_,$plot_mz_max_), ylim=c(0,$plot_int_max), cex=0.1, type="l", axes=FALSE)\n!;
							$text="scan=$scan_";
							if ($first==1) { $first=0; $text.=" m/z=[$plot_mz_min_-$plot_mz_max_] log10(int)=$plot_int_max_log10"; }
							print OUT2 qq!text(($plot_mz_min+$plot_mz_max)/2, 0.9*$plot_int_max, "$text",cex =1.2)\n!;
							for($i=0;$i<=2;$i++)
							{
								print OUT2 qq!lines(y ~ x$i, type="p", pch=20, cex=2, col="red")\n!;
							}
							for($i=0;$i<=2;$i++)
							{
								print OUT2 qq!lines(y ~ x_$i, type="p", pch=20, cex=2, col="blue")\n!;
							}
						}

						print OUT2 qq!savePlot(filename="$dir/$dir_/$pep-$mod-$charge.png",type="png")!;
						close(OUT2);
						system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
						system(qq!del R-infile.txt!);
						#system(qq!del $peptide_filename!);
					}
					$temp=$scan_map{$scan};
					$message="";
					while($temp=~s/^(\S+)\s//)
					{
						$scan_=$1;
						$temp_="$dir/$dir_/$pep-$mod-$charge-$scan_.txt";
						$temp_=~s/\//\\/g;
						system(qq!del "$temp_"!);
					}
					print OUT qq!$message\t$pep\t$mod\t$charge\t$delta_mass\t$diff\t$unique_peptides_mass{$key}\t$scan_diff\t$unique_peptides_scan{$key}\n!;
				}
			}
		}
	}
	close(OUT);
	$temp_="$dir/$dir_";
	$temp_=~s/\//\\/g;
	system(qq!del "$temp_\\*.mgf"!);
}

