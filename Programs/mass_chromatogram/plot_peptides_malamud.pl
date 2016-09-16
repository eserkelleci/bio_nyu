#!/usr/local/bin/perl
#
sub numerically { $a <=> $b; }

#$Rlocation="C:\\Program Files (x86)\\R\\R-2.9.1\\bin\\Rterm.exe";
$Rlocation="C:\\R\\bin\\x64\\Rterm.exe";
$this_location="D:/Programs/mass_chromatogram";
$this_location_="D:\\Programs\\mass_chromatogram";
$error=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $peptidelistname=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $tandemfilename=$ARGV[2];} else { $error=1; }

$threshold=1e-1;
$proton_mass=1.007276;
$c12_13_mass_diff=1.0033548;

$dir="$filename-$peptidelistname.dir";
$dir=~s/\\/\//g;
$dir_=$dir;
$dir_=~s/\//\\/g;
mkdir($dir);

if ($error==0)
{
	if (open(TEST,"$filename-$peptidelistname.res"))
	{
		close(TEST);
	}
	else
	{
		system(qq!mzXMLGetMassChrom.exe $filename $peptidelistname!);
	}
	if (open(TEST,"$filename.MS1.mgf"))
	{
		close(TEST);
	}
	else
	{
		system(qq!mzXMLtoMGF.exe $filename 1!); ###################
	}
	if (open(IN,"$filename-$peptidelistname.res"))
	{
		$point_count=0;
		$line=<IN>;
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				$spectrum_scan[$point_count]=$1;
				$spectrum_mz[$point_count]=$2;
				$spectrum_int[$point_count]=$3;
				$point_count++;
			}
		}
		print qq!$point_count points\n!;
		close(IN);
		$pep_count=0;
		if (open(IN,"$peptidelistname"))
		{
			$peak_num_max=0;
			while ($line=<IN>)
			{
				chomp($line);
				if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					$pep{$1}=1;
					$pep[$pep_count]=$1;
					$mod[$pep_count]=$2;
					$charge[$pep_count]=$3;
					$mz[$pep_count]=$4;
					$peak_num[$pep_count]=$6;
					$rt_min[$pep_count]=$8;
					$rt_max[$pep_count]=$9;
					$mz_min[$pep_count]=$10;
					$mz_max[$pep_count]=$11;
					$peak{"$pep[$pep_count]#$mod[$pep_count]#$peak_num[$pep_count]#$charge[$pep_count]"}=$pep_count;
					if ($peak_num_max<$peak_num[$pep_count]) { $peak_num_max=$peak_num[$pep_count]; }
					if ($charge_min{"$pep[$pep_count]#$mod[$pep_count]"}!~/\w/ or $charge_min{"$pep[$pep_count]#$mod[$pep_count]"}>$charge[$pep_count]) { $charge_min{"$pep[$pep_count]#$mod[$pep_count]"}=$charge[$pep_count]; }
					if ($charge_max{"$pep[$pep_count]#$mod[$pep_count]"}!~/\w/ or $charge_max{"$pep[$pep_count]#$mod[$pep_count]"}<$charge[$pep_count]) { $charge_max{"$pep[$pep_count]#$mod[$pep_count]"}=$charge[$pep_count]; }
					$pep_count++;
				}
			}
			close(IN);
			print qq!$pep_count peptides ($peak_num_max) ($charge_min{"$pep[0]#$mod[0]"}-$charge_max{"$pep[0]#$mod[0]"})\n!;
			$pep_mod_count=0;
			%pepmod_peak_ok=();
			%pepmod_peak_ok_max=();
			%pepmod_peak_charge=();
			%pepmod_peak_scan=();
			foreach $pep_mod (sort keys %charge_min)
			{
				if ($pep_mod=~/^([^#]*)#([^#]*)$/)
				{
					$pep=$1;
					$mod=$2;
					if ($mod!~/Standard/)
					{
						$pep_std="";
						$mod_std="";
						for($j=0;$j<$pep_count;$j++)
						{
							if ($pep=~/^$pep[$j]$/ and $mod[$j]=~/Standard/)
							{
								$pep_std=$pep[$j];
								$mod_std=$mod[$j];
							}
						}
						$mh{"$pep#$mod"}=$mz[$peak{"$pep#$mod#1#1"}];
						$diff{"$pep#$mod"}=$mz[$peak{"$pep_std#$mod_std#1#1"}]-$mz[$peak{"$pep#$mod#1#1"}];
						print "$pep_mod_count. $pep $mod ($pep_std $mod_std)\n";
						@plot_max=();
						$plot_min_scan=1000000;
						$plot_max_scan=0;
						@index_count=();
						@index_count_max=();
						$index_count_max=0;
						%index=();
						%scans=();
						for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
						{
							$plot_max[$j]=0;
							for($k=0;$k<=$peak_num_max;$k++)
							{
								$index_count[$j][$k]=0;
								for($l=0;$l<$point_count;$l++)
								{
									if ($rt_min[$peak{"$pep#$mod#$k#$j"}]<=$spectrum_scan[$l] and 
										$spectrum_scan[$l]<=$rt_max[$peak{"$pep#$mod#$k#$j"}] and 
										$mz_min[$peak{"$pep#$mod#$k#$j"}]<=$spectrum_mz[$l] and 
										$spectrum_mz[$l]<=$mz_max[$peak{"$pep#$mod#$k#$j"}])
									{
										$index{"$j#$spectrum_scan[$l]#$k"}=$l;
										$scans{"$spectrum_scan[$l]#$j"}=1;
										if ($plot_min_scan>$spectrum_scan[$l]) { $plot_min_scan=$spectrum_scan[$l]; }
										if ($plot_max_scan<$spectrum_scan[$l]) { $plot_max_scan=$spectrum_scan[$l]; }
										$index_count[$j][$k]++;
									}
								}
								if ($index_count_max[$j]<$index_count[$j][$k]) { $index_count_max[$j]=$index_count[$j][$k]; }
								if ($index_count_max<$index_count[$j][$k]) { $index_count_max=$index_count[$j][$k]; }
							}
						}
						@plot_max_std=();
						$plot_min_scan_std=1000000;
						$plot_max_scan_std=0;
						@index_count_std=();
						@index_count_max_std=();
						$index_count_max_std=0;
						%index_std=();
						%scans_std=();
						for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
						{
							$plot_max_std[$j]=0;
							for($k=0;$k<=$peak_num_max;$k++)
							{
								$index_count_std[$j][$k]=0;
								for($l=0;$l<$point_count;$l++)
								{
									if ($rt_min[$peak{"$pep_std#$mod_std#$k#$j"}]<=$spectrum_scan[$l] and 
										$spectrum_scan[$l]<=$rt_max[$peak{"$pep_std#$mod_std#$k#$j"}] and 
										$mz_min[$peak{"$pep_std#$mod_std#$k#$j"}]<=$spectrum_mz[$l] and 
										$spectrum_mz[$l]<=$mz_max[$peak{"$pep_std#$mod_std#$k#$j"}])
									{
										$index_std{"$j#$spectrum_scan[$l]#$k"}=$l;
										$scans_std{"$spectrum_scan[$l]#$j"}=1;
										if ($plot_min_scan_std>$spectrum_scan[$l]) { $plot_min_scan_std=$spectrum_scan[$l]; }
										if ($plot_max_scan_std<$spectrum_scan[$l]) { $plot_max_scan_std=$spectrum_scan[$l]; }
										$index_count_std[$j][$k]++;
									}
								}
								if ($index_count_max_std[$j]<$index_count_std[$j][$k]) { $index_count_max_std[$j]=$index_count_std[$j][$k]; }
								if ($index_count_max_std<$index_count_std[$j][$k]) { $index_count_max_std=$index_count_std[$j][$k]; }
							}
						}
						
						$max=0;
						$max_charge[$pep_mod_count]=0;
						$max_scan[$pep_mod_count]=0;
						foreach $scan_ (sort numerically keys %scans)
						{
							$scan=$scan_; 
							if ($scan=~s/#([0-9]+)$//)
							{
								$j=$1;
								$max_=1;
								if ($spectrum_int[$index{"$j#$scan#1"}]>0 and $index{"$j#$scan#1"}=~/\w/ and 
								    $spectrum_int[$index{"$j#$scan#2"}]>0 and $index{"$j#$scan#2"}=~/\w/)
								{
									$max_*=$spectrum_int[$index{"$j#$scan#1"}]*$spectrum_int[$index{"$j#$scan#2"}];
								}
								if ($spectrum_int[$index_std{"$j#$scan#1"}]>0 and $index_std{"$j#$scan#1"}=~/\w/ and 
								    $spectrum_int[$index_std{"$j#$scan#2"}]>0 and $index_std{"$j#$scan#2"}=~/\w/)
								{
									$max_*=$spectrum_int[$index_std{"$j#$scan#1"}]*$spectrum_int[$index_std{"$j#$scan#2"}];
								}
								if ($max<$max_)
								{
									$max=$max_;
									$max_charge[$pep_mod_count]=$j;
									$max_scan[$pep_mod_count]=$scan;
								}
							}
						}
						$pep_mod_count++;
					}
				}
			}
		}
		close(IN);
		system(qq!del "$filename-$peptidelistname.res"!);
		
		%scans_ms2=();
		$scans_ms2_min=1000000000;
		$scans_ms2_max=0;
		open (IN,"$tandemfilename") || die "Could not open $filename\n";
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
					if ($pep{$pep}=~/\w/)
					{
						if ($expect<=$threshold)
						{
							if ($peptide_expect{"$pep"}!~/\w/ or $peptide_expect{"$pep"}<$expect)
							{
								$peptide_expect{"$pep"}=$expect;
								$peptide_mass{"$pep"}=$mexp;
								$peptide_scan{"$pep"}=$scan;
								$scans_ms2{$scan}=1;
								if ($scans_ms2_max<$scan) { $scans_ms2_max=$scan; }
								if ($scans_ms2_min>$scan) { $scans_ms2_min=$scan; }
							}
						}
					}
				}
			}
		}
		close(IN);
		
		@scans_ms1=();
		$scans_ms1_count=0;
		if(open (IN, "$filename.MS1.mgf"))
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
							if(open (OUT,">$dir/$scan.mgf"))
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
			
			@scans_ms1_sorted = sort { $a <=> $b } @scans_ms1;
			%scan_map=();
			$j=0;
			foreach $i (sort { $a <=> $b } @max_scan)
			{
				for(;$j<=$scans_ms1_count and $scans_ms1_sorted[$j]<$i;$j++) { ; }
				$j--;
				$scan_map{$i}="";
				for($k=$j-4;$k<=$j+4;$k++) { $scan_map{$i}.="$scans_ms1_sorted[$k] "; }
				#print "$i: $scan_map{$i}\n";
			}
			%scan_map_ms2=();
			$j=0;
			foreach $i (sort { $a <=> $b } keys %scans_ms2)
			{
				for(;$j<=$scans_ms1_count and $scans_ms1_sorted[$j]<$i;$j++) { ; }
				$j--;
				$scan_map_ms2{$i}="";
				for($k=$j-4;$k<=$j+4;$k++) { $scan_map_ms2{$i}.="$scans_ms1_sorted[$k] "; }
				#print "$i: $scan_map_ms2{$i}\n";
			}
			$pep_mod_count=0;
			foreach $pep_mod (sort keys %charge_min)
			{
				if ($pep_mod=~/^([^#]*)#([^#]*)$/)
				{
					$pep=$1;
					$mod=$2;
					if ($mod!~/Standard/)
					{
						if ($diff{"$pep#$mod"}>0)
						{
							$mz_min=$mh{"$pep#$mod"}-0.5;
							$mz_max=$mh{"$pep#$mod"}+$diff{"$pep#$mod"}+2.5;
						}
						else
						{
							$mz_min=$mh{"$pep#$mod"}+$diff{"$pep#$mod"}-0.5;
							$mz_max=$mh{"$pep#$mod"}+2.5;
						}
						print qq!\n**** $pep $mod $diff{"$pep#$mod"} $mh{"$pep#$mod"} [$mz_min,$mz_max]\n!;
						print qq!MS1: $max_scan[$pep_mod_count]:$scan_map{$max_scan[$pep_mod_count]}\n!;
						if ($peptide_scan{$pep}=~/\w/)
						{
							print qq!MS2: $peptide_scan{$pep}:$scan_map_ms2{$peptide_scan{$pep}}\n!;
						};
						for($charge=1;$charge<=3;$charge++)
						{
							print qq!$charge\n!;
							$mz=($mh{"$pep#$mod"}-$proton_mass+$charge*$proton_mass)/$charge;
							$plot_mz_min=($mz_min-$proton_mass+$charge*$proton_mass)/$charge;
							$plot_mz_max=($mz_max-$proton_mass+$charge*$proton_mass)/$charge;
							$plot_int_max=0;
							$plot_int_max=0;
							$temp=$scan_map{$max_scan[$pep_mod_count]};
							$message="";
							while($temp=~s/^(\S+)\s//)
							{
								$scan_=$1;
								if(open (IN,"$dir/$scan_.mgf"))
								{
									if(open (OUT_,">$dir/$pep-$mod-$charge-$scan_.txt"))
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
													print OUT_ qq!$mz_\t0\n!;
													print OUT_ qq!$mz_\t$int_\n!;
													print OUT_ qq!$mz_\t0\n!;
													if ($plot_int_max<$int_) { $plot_int_max=$int_; }
													for($i=0;$i<=1;$i++)
													{
														$mz__=$mz+$i*$c12_13_mass_diff/$charge;
														if (abs($mz_-$mz__)<=20*1e-6*$mz_)
														{
															if ($plot_int_max_<$int_) { $plot_int_max_=$int_; }
														}
														$mz__=$mz+($i*$c12_13_mass_diff+$diff{"$pep#$mod"})/$charge;
														if (abs($mz_-$mz__)<=20*1e-6*$mz_)
														{
															if ($plot_int_max_<$int_) { $plot_int_max_=$int_; }
														}
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
									$message.="$dir/$pep-$mod-$charge-$scan_.txt";
								}
							}
							if ($plot_int_max)
							{
								print qq!plot\n!;
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
										$mz_=$mz+($i*$c12_13_mass_diff+$diff{"$pep#$mod"})/$charge;
										print OUT2 qq!x_$i <- c($mz_,$mz_)\n!;
									}
									$temp=$scan_map{$max_scan[$pep_mod_count]};
									$message="";
									$first=1;
									while($temp=~s/^(\S+)\s//)
									{
										$scan_=$1;
										$plot_mz_min_=int($plot_mz_min); 
										$plot_mz_max_=int($plot_mz_max+1); 
										if ($plot_int_max_>0) { $plot_int_max__=$plot_int_max_; } else { $plot_int_max__=$plot_int_max; }
										$plot_int_max_log10=log($plot_int_max__)/log(10); $plot_int_max_log10=~s/\.([0-9]).*$/.$1/;
										print OUT2 qq!Datafile$scan_ <- read.table("$dir/$pep-$mod-$charge-$scan_.txt", header=TRUE, sep="\t")\n!;
										print OUT2 qq!plot(int ~ mz, data=Datafile$scan_, xlim=c($plot_mz_min_,$plot_mz_max_), ylim=c(0,$plot_int_max__), cex=0.1, type="l", axes=FALSE)\n!;
										$text="scan=$scan_";
										if ($first==1) { $first=0; $text.=" m/z=[$plot_mz_min_-$plot_mz_max_] log10(int)=$plot_int_max_log10"; }
										print OUT2 qq!text(($plot_mz_min+$plot_mz_max)/2, 0.9*$plot_int_max__, "$text",cex =1.2)\n!;
										for($i=0;$i<=2;$i++)
										{
											print OUT2 qq!lines(y ~ x$i, type="p", pch=20, cex=2, col="red")\n!;
										}
										for($i=0;$i<=2;$i++)
										{
											print OUT2 qq!lines(y ~ x_$i, type="p", pch=20, cex=2, col="blue")\n!;
										}
									}

									print OUT2 qq!savePlot(filename="$dir/$pep-$mod-$charge.png",type="png")!;
									close(OUT2);
									system(qq!"$Rlocation" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
									#system(qq!del R-infile.txt!);
									#system(qq!del $peptide_filename!);
								}
								$temp=$scan_map{$max_scan[$pep_mod_count]};
								$message="";
								while($temp=~s/^(\S+)\s//)
								{
									$scan_=$1;
									$temp_="$dir/$pep-$mod-$charge-$scan_.txt";
									$temp_=~s/\//\\/g;
									#system(qq!del "$temp_"!);
								}
							}
						}
						$pep_mod_count++;
					}
				}
			}
			
		}
	}
}
