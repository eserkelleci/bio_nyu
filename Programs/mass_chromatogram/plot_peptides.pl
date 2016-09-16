#!/usr/local/bin/perl
#
sub numerically { $a <=> $b; }

#$Rlocation="C:\\Program Files\\R\\R-2.4.0\\bin\\Rterm.exe";
$Rlocation="C:\\R\\bin\\x64\\Rterm.exe";
#$Rlocation="C:\\Program Files (x86)\\R\\R-2.9.2\\bin\\Rterm.exe";
$this_location="D:/Programs/mass_chromatogram";
$this_location_="D:\\Programs\\mass_chromatogram";
$error=0;
$del_text_files=1;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $peptidelistname=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $zoom=$ARGV[2];} else { $zoom=1; }

$dir="$filename-$peptidelistname.dir";
$dir=~s/\\/\//g;
$dir_=$dir;
$dir_=~s/\//\\/g;
mkdir($dir);
open(OUT_INTEGRAL,">$dir/integral.txt");
print OUT_INTEGRAL qq!pep\tmod\tcharge\tintegral\tscan_min\tscan_max\tscan_width\n!;
$distr_min_index="";
$distr_max_index="";
if ($error==0)
{

	if (open(IN,"isotope-distr-mass.txt"))
	{
		$line=<IN>;
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/)
			{
				$k=$1/10;
				$k=~s/\..*$//;
				if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/)
				{
					$distr{"$k#0"}=$3;
					$distr{"$k#1"}=$4;
					$distr{"$k#2"}=$5;
					$distr{"$k#3"}=$6;
					$distr{"$k#4"}=$7;
					$distr{"$k#5"}=$8;
					$distr{"$k#6"}=$9;
					$distr{"$k#7"}=$10;
					$distr{"$k#8"}=$11;
					$distr{"$k#9"}=$12;
					if ($distr_min_index!~/\w/ or $distr_min_index>$k) { $distr_min_index=$k; }
					if ($distr_max_index!~/\w/ or $distr_max_index<$k) { $distr_max_index=$k; }
				}
			}
		}
		close(IN);
	} else { print qq!Error: file not found (isotope-ratio-limits.txt)\n!; $error=1; }
}
print qq!distr_min_index=$distr_min_index, distr_max_index=$distr_max_index\n!;

if ($error==0)
{
	if (open(IN,"isotope-ratio-limits.txt"))
	{
		$line=<IN>;
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
			{
				$k=$1/50;
				$k=~s/\..*$//;
				if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
				{
					$limits{"$k#L#1"}=$2;
					$limits{"$k#H#1"}=$3;
					$limits{"$k#L#2"}=$4;
					$limits{"$k#H#2"}=$5;
					$limits{"$k#L#3"}=$6;
					$limits{"$k#H#3"}=$7;
					$limits{"$k#L#4"}=$8;
					$limits{"$k#H#4"}=$9;
					$limits{"$k#L#5"}=$10;
					$limits{"$k#H#5"}=$11;
				}
			}
		}
		close(IN);
	} else { print qq!Error: file not found (isotope-distr-mass.txt)\n!; $error=1; }
}

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
		#system(qq!mzXMLtoMGF.exe $filename 1!); ###################
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
					@plot_max=();
					$plot_min_scan=1000000;
					$plot_max_scan=0;
					@index_count=();
					@index_count_max=();
					$index_count_max=0;
					print "$pep_mod_count. $pep $mod ";
					%ok=();
					$ok_max_global=0;
					%index=();
					%scans=();
					for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
					{
						$plot_max[$j]=0;
						$plot_max_ok[$j]=0;
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
					foreach $scan_ (sort numerically keys %scans)
					{
						$scan=$scan_; 
						if ($scan=~s/#([0-9]+)$//)
						{
							$j=$1;
							$ok=1;
							if ($spectrum_int[$index{"$j#$scan#1"}]>0 and $index{"$j#$scan#1"}=~/\w/ and $spectrum_int[$index{"$j#$scan#2"}]>0 and $index{"$j#$scan#2"}=~/\w/)
							{
								for($k=2;$k<=$peak_num_max;$k++)
								{
									$k_=$k-1;
									$test=$spectrum_int[$index{"$j#$scan#$k"}]/$spectrum_int[$index{"$j#$scan#1"}];
									$l=$j*$mz_min[$peak{"$pep#$mod#$k#$j"}]/10;
									$l=~s/\..*$//;
									if ($l<$distr_min_index) { $l=$distr_min_index; } 
									if ($l>$distr_max_index) { $l=$distr_max_index; } 
									$test/=$distr{"$l#$k_"};
									$l_=$j*$mz_min[$peak{"$pep#$mod#$k#$j"}]/50;
									$l_=~s/\..*$//;
									if($test<$limits{"$l_#L#$k_"} or $limits{"$l_#H#$k_"}<$test) { $ok=0; }
									if ($plot_max[$j]<$spectrum_int[$index{"$j#$scan#$k_"}]) { $plot_max[$j]=$spectrum_int[$index{"$j#$scan#$k_"}]; }
								}
								if ($plot_max[$j]<$spectrum_int[$index{"$j#$scan#0"}]) { $plot_max[$j]=$spectrum_int[$index{"$j#$scan#0"}]; }
							} else { $ok=0; }
							if ($ok==1)
							{
								if ($spectrum_int[$index{"$j#$scan#0"}]>0.5*$spectrum_int[$index{"$j#$scan#1"}])
								{
									$ok_=1;
									for($k=1;$k<=$peak_num_max-1;$k++)
									{
										$test=$spectrum_int[$index{"$j#$scan#$k"}]/$spectrum_int[$index{"$j#$scan#0"}];
										$l=$j*$mz_min[$peak{"$pep#$mod#$k#$j"}]/10;
										$l=~s/\..*$//;
										if ($l<$distr_min_index) { $l=$distr_min_index; } 
										if ($l>$distr_max_index) { $l=$distr_max_index; } 
										$test/=$distr{"$l#$k"};
										$l_=$j*$mz_min[$peak{"$pep#$mod#$k#$j"}]/50;
										$l_=~s/\..*$//;
										if($limits{"$l_#H#$k"}<$test) { $ok_=0; }
									}
								} else { $ok_=0; }
								if ($ok_==1) { $ok=0; }
							}
							if ($ok==1) 
							{ 
								$ok{"$scan#$j"}=1;
								for($k=1;$k<=$peak_num_max-1;$k++)
								{
									if ($ok_max_global<$spectrum_int[$index{"$j#$scan#$k"}])
									{
										$ok_max_global=$spectrum_int[$index{"$j#$scan#$k"}];
									}
								}
							} else { $ok{"$scan#$j"}=0; }
						}
					}

					%ok_=();
					%ok__max=();
					for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
					{
						$plot_max_ok[$j]=0;
						$scan_avg=7;
						@scans=();
						$l_max=0;
						foreach $scan_ (sort numerically keys %scans)
						{
							$scan=$scan_; 
							if ($scan=~s/#$j$//)
							{
								$scans[$l_max++]=$scan;
							}
						}
						for($l=0;$l<$l_max;$l++)
						{
							$ok_{"$scans[$l]#$j"}=0;
							$ok_max{"$scans[$l]#$j"}=0;
							$temp_count=0;
							$temp_count_=0;
							for($m=$l-$scan_avg;$m<=$l+$scan_avg;$m++)
							{
								if (0<=$m and $m<$l_max)
								{
									if (abs($scans[$l]-$scans[$m])<750)
									{
										$ok_{"$scans[$l]#$j"}+=$ok{"$scans[$m]#$j"};
										for($k=1;$k<=$peak_num_max;$k++)
										{
											if ($ok_max{"$scans[$l]#$j"}<$spectrum_int[$index{"$j#$scans[$m]#$k"}])
											{
												$ok_max{"$scans[$l]#$j"}=$spectrum_int[$index{"$j#$scans[$m]#$k"}];
											}
										}
										$temp_count++;
										if ($ok{"$scans[$m]#$j"}>0) { $temp_count_++; }
									} #else { $m=$l+$scan_avg+1; }
								}
							}
							if ($temp_count>0) { $ok_{"$scans[$l]#$j"}/=$temp_count; } else { $ok_{"$scans[$l]#$j"}=0; }
							if ($temp_count<=1) { $ok_{"$scans[$l]#$j"}=0; } 
							if ($ok_{"$scans[$l]#$j"}>0) 
							{ 
								if ($pepmod_peak_ok{"$pep#$mod"}<$ok_{"$scans[$l]#$j"} and $ok_max_global*0.3<$ok_max{"$scans[$l]#$j"})
								{
									$pepmod_peak_ok{"$pep#$mod"}=$ok_{"$scans[$l]#$j"};
									$pepmod_peak_ok_max{"$pep#$mod"}=$ok_max{"$scans[$l]#$j"};
									$pepmod_peak_charge{"$pep#$mod"}=$j;
									$pepmod_peak_scan{"$pep#$mod"}=$scans[$l];
									$pepmod_peak_scan_index{"$pep#$mod"}=$l;
									$pepmod_peak_mz{"$pep#$mod"}=$spectrum_mz[$index{"$j#$scans[$l]#1"}];
								}
							} 
							if ($ok{"$scans[$l]#$j"}==1) 
							{
								for($k=1;$k<=$peak_num_max;$k++)
								{
									if ($plot_max_ok[$j]<$spectrum_int[$index{"$j#$scans[$l]#$k"}]) { $plot_max_ok[$j]=$spectrum_int[$index{"$j#$scans[$l]#$k"}]; }
								}
							}
						}
						if ($j==$pepmod_peak_charge{"$pep#$mod"})
						{
							$gap_max=5;
							$gap=0;
							$pepmod_peak_scan_max{"$pep#$mod"}=$pepmod_peak_scan{"$pep#$mod"};
							for($l=$pepmod_peak_scan_index{"$pep#$mod"}+1;$l<$l_max and $gap<=$gap_max;$l++)
							{
								if ($ok_{"$scans[$l]#$j"}>0.1 and abs($scans[$l]-$scans[$l-1-$gap])<100)
								{
									$pepmod_peak_scan_max{"$pep#$mod"}=$scans[$l];
									$gap=0;
								} else { $gap++; }
							}
							if ($pepmod_peak_scan_index{"$pep#$mod"}>=5) { $pepmod_peak_scan_min_{"$pep#$mod"}=$scans[$pepmod_peak_scan_index{"$pep#$mod"}-5]; } else { $pepmod_peak_scan_min_{"$pep#$mod"}=$scans[0]; }
							$gap=0;
							$pepmod_peak_scan_min{"$pep#$mod"}=$pepmod_peak_scan{"$pep#$mod"};
							for($l=$pepmod_peak_scan_index{"$pep#$mod"}-1;0<=$l and $gap<=$gap_max;$l--)
							{
								#print qq!$scans[$l]: $ok_{"$scans[$l]#$j"}\n!;
								if ($ok_{"$scans[$l]#$j"}>0.1 and abs($scans[$l]-$scans[$l+1+$gap])<100)
								{
									$pepmod_peak_scan_min{"$pep#$mod"}=$scans[$l];
									$gap=0;
								} else { $gap++; }
							}
							#print qq!\n###$pep,$mod: $pepmod_peak_scan{"$pep#$mod"}, ($pepmod_peak_scan_min{"$pep#$mod"},$pepmod_peak_scan_max{"$pep#$mod"})\n!;
							if ($pepmod_peak_scan_index{"$pep#$mod"}<$l_max-5) { $pepmod_peak_scan_max_{"$pep#$mod"}=$scans[$pepmod_peak_scan_index{"$pep#$mod"}+5]; } else { $pepmod_peak_scan_max_{"$pep#$mod"}=$scans[$l_max-1]; }
						}
					}
					for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
					{
						$plot_max_zoom[$j]=0;
						$plot_max__ok_zoom[$j]=0;
						foreach $scan_ (sort numerically keys %scans)
						{
							$scan=$scan_; 
							if ($scan=~s/#$j$//)
							{
								if ($pepmod_peak_scan_min{"$pep#$mod"}<=$scan and $scan<=$pepmod_peak_scan_max{"$pep#$mod"})
								{
									if ($spectrum_int[$index{"$j#$scan#1"}]>0 and $index{"$j#$scan#1"}=~/\w/ and $spectrum_int[$index{"$j#$scan#2"}]>0 and $index{"$j#$scan#2"}=~/\w/)
									{
										for($k=0;$k<=$peak_num_max;$k++)
										{
											if ($plot_max_zoom[$j]<$spectrum_int[$index{"$j#$scan#$k"}]) { $plot_max_zoom[$j]=$spectrum_int[$index{"$j#$scan#$k"}]; }
											if ($ok{"$scans#$j"}==1) 
											{
												if ($plot_max_ok_zoom[$j]<$spectrum_int[$index{"$j#$scan#$k"}]) { $plot_max_ok_zoom[$j]=$spectrum_int[$index{"$j#$scan#$k"}]; }
											}
										}
									}
								}
							}
						}
						my $integral=0;
						my $integral_min=1000000;
						my $integral_max=0;
						foreach $scan_ (sort numerically keys %scans)
						{
							$scan=$scan_; 
							if ($scan=~s/#$j$//)
							{
								if ($pepmod_peak_scan_min{"$pep#$mod"}<=$scan and $scan<=$pepmod_peak_scan_max{"$pep#$mod"})
								{
									if ($spectrum_int[$index{"$j#$scan#1"}]>0 and $index{"$j#$scan#1"}=~/\w/ and $spectrum_int[$index{"$j#$scan#2"}]>0 and $index{"$j#$scan#2"}=~/\w/)
									{
										for($k=1;$k<=$peak_num_max;$k++)
										{
											if ($spectrum_int[$index{"$j#$scan#$k"}]>0 and $index{"$j#$scan#$k"}=~/\w/)
											{
												$integral+=$spectrum_int[$index{"$j#$scan#$k"}];
												if ($integral_min>$scan) { $integral_min=$scan; }
												if ($integral_max<$scan) { $integral_max=$scan; }
											}
										}
									}
								}
							}
						}
						my $width=$integral_max-$integral_min;
						if ($width>0)
						{
							print OUT_INTEGRAL qq!$pep\t$mod\t$j\t$integral\t$integral_min\t$integral_max\t$width\n!;
						}
						if (open(OUT,">$dir/$pep-$mod-z$j.txt"))
						{
							print OUT qq!scan!;
							for($k=0;$k<=$peak_num_max;$k++)
							{
								print OUT qq!\tmz$k\tint$k!;
							}
							print OUT qq!\tok\tok_zoom\n!;
							foreach $scan_ (sort numerically keys %scans)
							{
								$scan=$scan_; 
								if ($scan=~s/#$j$//)
								{
									print OUT qq!$scan!;
									for($k=0;$k<=$peak_num_max;$k++)
									{
										if ($index{"$j#$scan#$k"}=~/\w/)
										{
											if ($spectrum_mz[$index{"$j#$scan#$k"}]=~/\w/ and $spectrum_int[$index{"$j#$scan#$k"}]=~/\w/)
											{
												print OUT qq!\t$spectrum_mz[$index{"$j#$scan#$k"}]\t$spectrum_int[$index{"$j#$scan#$k"}]!;
											}
										}
										else { print OUT qq!\t-1\t-1!; }
									}
									if ($plot_max_ok[$j]) { $temp=$plot_max_ok[$j]*1.05; } else { $temp=$plot_max[$j]*1.05; }
									if ($plot_max_ok_zoom[$j]) { $temp_=$plot_max_ok_zoom[$j]*1.05; } else { $temp_=$plot_max_zoom[$j]*1.05; }
									if ($ok{"$scan#$j"}==1) { print OUT qq!\t$temp\t$temp_!; } else { print OUT qq!\t-10000000000\t-10000000000!; }
									print OUT qq!\n!;
								}
							}
							close(OUT);
						}
					}

					@colors=("rgb(51,153,255, max=255)","rgb(0,0,0, max=255)","rgb(255,51,51, max=255)","rgb(204,204,153, max=255)");
					if ($index_count_max>0 and $plot_max_scan-$plot_min_scan>0)
					{
						print qq! Plotting\n!;
						for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
						{
							if(open(OUT,">$dir/$pep\_$mod-z$j-distr.txt"))
							{
								print OUT qq!scan!;
								for($k=0;$k<=3;$k++)
								{
									print OUT qq!\tint$k!;
								}
								print OUT qq!\n!;
								$delta_scan=0.01*($plot_max_scan-$plot_min_scan);
								for($scan=$plot_max_scan;$scan<=$plot_max_scan+3*$delta_scan;$scan++)
								{
									print OUT qq!$scan\t0!;
									for($k=1;$k<=3;$k++)
									{
										$l=$j*$mz_min[$peak{"$pep#$mod#$k#$j"}]/10;
										$l=~s/\..*$//;
										if ($l<$distr_min_index) { $l=$distr_min_index; } 
										if ($l>$distr_max_index) { $l=$distr_max_index; } 
										$k_=$k-1;
										$temp=0.7*1.05*$distr{"$l#$k_"}*Gaussian($scan,$plot_max_scan+1.5*$delta_scan,$delta_scan/2);
										if ($plot_max_ok[$j]>0) { $temp*=$plot_max_ok[$j]; } else { $temp*=$plot_max[$j]; }
										print OUT qq!\t$temp!;
									}
									print OUT qq!\n!;
								}
								close(OUT);
							}
						}
						if(open(OUT,">R-infile.txt"))
						{
							my $print_this=0;
							my @msms=();
							my @msms_=();
							if(open(IN_,"$dir/$pep\_$mod.scans.txt"))
							{
								while($line=<IN_>)
								{
									chomp($line);
									if ($line=~/^([^\t]+)\t([^\t]+)$/)
									{
										$j=$1;
										$msms[$1].="$2,";
										if ($plot_max_ok[$j]>0) { $msms_=1.06*$plot_max_ok[$j]; } else { $msms_=1.06*$plot_max[$j]; }
										$msms=~s/\.([0-9]).*$/.$1/;
										$msms_[$j].="$msms_,";
									}
								}
								close(IN_);
							}
							$temp=$charge_max{"$pep#$mod"}-$charge_min{"$pep#$mod"}+1;
							print OUT qq!windows(width=11, height=8)
										par(tcl=0.2)
										par(mfrow=c($temp,1))
										par(mai=c(0.3,0.5,0.2,0.1))
										par(font=1)
							!;
							for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
							{
								print OUT qq!Datafile_$j <- read.table("$dir/$pep-$mod-z$j.txt",header=TRUE)\n!;
								print OUT qq!Datafile__$j <- read.table("$dir/$pep\_$mod-z$j-distr.txt",header=TRUE)\n!;
							}
							for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
							{
								if ($index_count_max[$j]>0)
								{
									for($k=0;$k<=$peak_num_max;$k++)
									{
										if ($plot_max[$j]>0)
										{
											if ($k==0)
											{
												$temp=$mod; $temp=~s/^[0-9]+$//; if ($temp=~/\w/) { $temp=" $temp"; }
												$temp="$pep$temp";
												if ($plot_max_ok[$j]>0)
												{
													print OUT qq!plot(int$k ~ scan, data=Datafile_$j, type="n", cex=0.65, axes=TRUE, xlim = c($plot_min_scan,$plot_max_scan), ylim = c(0,1.05*$plot_max_ok[$j]), main="$temp $j+", xlab="Scan", ylab="Intensity")\n!;
												}
												else
												{
													print OUT qq!plot(int$k ~ scan, data=Datafile_$j, type="n", cex=0.65, axes=TRUE, xlim = c($plot_min_scan,$plot_max_scan), ylim = c(0,1.05*$plot_max[$j]), main="$temp $j+", xlab="Scan", ylab="Intensity")\n!;
												}
												$print_this=1;
											}
											if ($index_count[$j][$k]>0)
											{
												print OUT qq!lines(int$k ~ scan, data=Datafile_$j, cex=0.5, pch=16,  type="p", col=$colors[$k])\n!;
												print OUT qq!lines(int$k ~ scan, data=Datafile__$j, lwd=2,  type="l", col=$colors[$k])\n!;
											}
										}
									}
									if ($plot_max[$j]>0)
									{
										print OUT qq!lines(ok ~ scan, data=Datafile_$j, cex=1, pch=16,  type="p", col="black")\n!;
										if ($msms[$j]=~/\w/)
										{
											$msms[$j]=~s/\,$//;
											$msms_[$j]=~s/\,$//;
											print OUT qq!x <- c($msms[$j])\n!;
											print OUT qq!y <- c($msms_[$j])\n!;
											print OUT qq!lines(y ~ x, cex=1.3, pch=16,  type="p", col="gray")\n!;
										}
									}
								}
							}
							print OUT qq!savePlot(filename="$dir/$pep\_$mod.png",type="png")\n!;
							close(OUT);
							if ($print_this==1)
							{
								system(qq!"$Rlocation" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
							}
							system(qq!del "R-infile.txt"!);
							#system(qq!del "R-outfile.txt"!);
						}
						if ($zoom==1)
						{
							#if ($pepmod_peak_scan_max{"$pep#$mod"}-$pepmod_peak_scan_min{"$pep#$mod"}<($plot_max_scan-$plot_min_scan)/20)
							#{
							#	my $temp=($pepmod_peak_scan_max{"$pep#$mod"}+$pepmod_peak_scan_min{"$pep#$mod"})/2;
							#	$pepmod_peak_scan_min{"$pep#$mod"}=$temp-($plot_max_scan-$plot_min_scan)/40;
							#	if ($pepmod_peak_scan_min{"$pep#$mod"}<0) { $pepmod_peak_scan_min{"$pep#$mod"}=0; }
							#	$pepmod_peak_scan_max{"$pep#$mod"}=$temp+($plot_max_scan-$plot_min_scan)/40;
							#}
							my $zoom_xlim_min=($pepmod_peak_scan_max{"$pep#$mod"}+$pepmod_peak_scan_min{"$pep#$mod"})/2-3*($pepmod_peak_scan_max{"$pep#$mod"}-$pepmod_peak_scan_min{"$pep#$mod"})/2;
							my $zoom_xlim_max=($pepmod_peak_scan_max{"$pep#$mod"}+$pepmod_peak_scan_min{"$pep#$mod"})/2+3*($pepmod_peak_scan_max{"$pep#$mod"}-$pepmod_peak_scan_min{"$pep#$mod"})/2;
							if(open(OUT,">R-infile.txt"))
							{
								my $print_this=0;
								my @msms=();
								my @msms_=();
								if(open(IN_,"$dir/$pep\_$mod.scans.txt"))
								{
									while($line=<IN_>)
									{
										chomp($line);
										if ($line=~/^([^\t]+)\t([^\t]+)$/)
										{
											$j=$1;
											$msms[$1].="$2,";
											if ($plot_max_ok_zoom[$j]>0) { $msms_=1.06*$plot_max_ok_zoom[$j]; } else { $msms_=1.06*$plot_max_zoom[$j]; }
											$msms=~s/\.([0-9]).*$/.$1/;
											$msms_[$j].="$msms_,";
										}
									}
									close(IN_);
								}
								$temp=$charge_max{"$pep#$mod"}-$charge_min{"$pep#$mod"}+1;
								print OUT qq!windows(width=11, height=8)
											par(tcl=0.2)
											par(mfrow=c($temp,1))
											par(mai=c(0.3,0.5,0.2,0.1))
											par(font=1)
								!;
								for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
								{
									print OUT qq!Datafile_$j <- read.table("$dir/$pep-$mod-z$j.txt",header=TRUE)\n!;
								}
								for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
								{
									if ($index_count_max[$j]>0)
									{
										for($k=0;$k<=$peak_num_max;$k++)
										{
											if ($plot_max_zoom[$j]>0)
											{
												if ($k==0)
												{
													$temp=$mod; $temp=~s/^[0-9]+$//; if ($temp=~/\w/) { $temp=" $temp"; }
													$temp="$pep$temp";
													if ($plot_max_ok_zoom[$j]>0)
													{
														print OUT qq!plot(int$k ~ scan, data=Datafile_$j, type="n", cex=0.65, axes=TRUE, xlim = c($zoom_xlim_min,$zoom_xlim_max), ylim = c(0,1.05*$plot_max_ok_zoom[$j]), main="$temp $j+", xlab="Scan", ylab="Intensity")\n!;
													}
													else
													{
														print OUT qq!plot(int$k ~ scan, data=Datafile_$j, type="n", cex=0.65, axes=TRUE, xlim = c($zoom_xlim_min,$zoom_xlim_max), ylim = c(0,1.05*$plot_max_zoom[$j]), main="$temp $j+", xlab="Scan", ylab="Intensity")\n!;
													}
													$print_this=1;
												}
												if ($index_count[$j][$k]>0)
												{
													print OUT qq!lines(int$k ~ scan, data=Datafile_$j, cex=1, pch=16,  type="p", col=$colors[$k])\n!;
												}
											}
										}
										if ($plot_max_zoom[$j]>0)
										{
											print OUT qq!lines(ok_zoom ~ scan, data=Datafile_$j, cex=1, pch=16,  type="p", col="black")\n!;
											if ($msms[$j]=~/\w/)
											{
												$msms[$j]=~s/\,$//;
												$msms_[$j]=~s/\,$//;
												print OUT qq!x <- c($msms[$j])\n!;
												print OUT qq!y <- c($msms_[$j])\n!;
												print OUT qq!lines(y ~ x, cex=1.3, pch=16,  type="p", col="gray")\n!;
											}
										}
									}
								}
								print OUT qq!savePlot(filename="$dir/$pep\_$mod\_zoom.png",type="png")\n!;
								close(OUT);
								if ($print_this==1)
								{
									system(qq!"$Rlocation" --no-restore --no-save < "R-infile.txt" > "R-outfile_.txt" 2>&1!);
								}
								system(qq!del "R-infile.txt"!);
								#system(qq!del "R-outfile_.txt"!);
							}
						}
					} else { print qq!\n!; }
					for($j=$charge_min{"$pep#$mod"};$j<=$charge_max{"$pep#$mod"};$j++)
					{
						if ($del_text_files!=0)
						{
							system qq!del "$dir_\\$pep-$mod-z$j.txt"!;
							system qq!del "$dir_\\$pep\_$mod-z$j-distr.txt"!;
						}
					}
					if ($del_text_files!=0)
					{
						system qq!del "$dir_\\$pep\_$mod.scans.txt"!;
					}
					for($l=$pepmod_peak_scan_min_{"$pep#$mod"};$l<=$pepmod_peak_scan_max_{"$pep#$mod"};$l++)
					{
						#print qq!$pep-$mod $l\n!;
						$scans_to_extract{$l}=1;
						$scans_to_extract_pepmod{$l}="$pep-$mod";
					}
					print qq!Max: $pepmod_peak_ok{"$pep#$mod"} $pepmod_peak_ok_max{"$pep#$mod"} $pepmod_peak_charge{"$pep#$mod"} $pepmod_peak_scan{"$pep#$mod"} ($pepmod_peak_scan_min{"$pep#$mod"}-$pepmod_peak_scan_max{"$pep#$mod"})\n!;
				}
				$pep_mod_count++;
			}
			if (open(IN,"$filename.MS1.mgf"))
			{
				$extract=0;
				while ($line=<IN>)
				{
					if ($line=~/^TITLE=Scan ([0-9]+)/i)
					{
						$scan=$1;
						if ($scans_to_extract{$scan}==1)
						{
							open(OUT,">$dir/$scans_to_extract_pepmod{$scan}-$scan.txt");
							print OUT qq!mz\tint\n!;
							$extract=1;
						}
					}
					if ($extract==1)
					{
						if ($line=~/^([0-9edED\-\+\.]+)\s+([0-9edED\-\+\.]+)\s*$/)
						{
							$mz=$1;
							print OUT qq!$mz\t0\n!;
							print OUT $line;
							print OUT qq!$mz\t0\n!;
						}
						if ($line=~/^END IONS$/i) 
						{
							close(OUT);
							$extract=0;
						}
					}
				}
				close(IN);
				if (opendir(dir,"$dir"))
				{
					my @allfiles=readdir dir;
					closedir dir;
					foreach $filename (@allfiles)
					{
						if ($filename=~/^([^\-]+)\-([^\-]*)\-([0-9]+)\.txt$/i)
						{
							$pep=$1;
							$mod=$2;
							$scan=$3;
							$extracted_files{"$pep#$mod"}.="#$filename#";
							$extracted_files_count{"$pep#$mod"}++;
						}
					}
				}
				foreach $pep_mod (sort keys %charge_min)
				{
					if ($pep_mod=~/^([^#]*)#([^#]*)$/)
					{
						$pep=$1;
						$mod=$2;
						#print qq!$pepmod_peak_mz{"$pep#$mod"} $pepmod_peak_charge{"$pep#$mod"} $pepmod_peak_scan{"$pep#$mod"} $extracted_files{"$pep#$mod"}\n!;
						if(open(OUT,">R-infile.txt"))
						{
							my $print_this=0;
							print OUT qq!windows(width=11, height=8)
										par(tcl=0.2)
										par(mfrow=c($extracted_files_count{"$pep#$mod"},1))
										par(mai=c(0,0,0,0))
										par(font=1)
							!;
							$temp=$extracted_files{"$pep#$mod"};
							for($j=0;$j<$extracted_files_count{"$pep#$mod"};$j++)
							{
								if ($temp=~s/^#([^#]+)#//)
								{
									$datafile=$1;
									print OUT qq!Datafile_$j <- read.table("$dir/$datafile",header=TRUE)\n!;
									$plot_min_mz=$pepmod_peak_mz{"$pep#$mod"}-5;
									$plot_max_mz=$pepmod_peak_mz{"$pep#$mod"}+5;
									print OUT qq!plot(int ~ mz, data=Datafile_$j, type="n", cex=0.65, axes=FALSE, xlim = c($plot_min_mz,$plot_max_mz), ylim=c(0,$pepmod_peak_ok_max{"$pep#$mod"}), main="", xlab="m/z", ylab="Intensity")\n!;
									print OUT qq!lines(int ~ mz, data=Datafile_$j, lwd=2,  type="l", col="black")\n!;
									print OUT qq!y <- c(-0.02*$pepmod_peak_ok_max{"$pep#$mod"},-0.02*$pepmod_peak_ok_max{"$pep#$mod"})\n!;
									for($k=0;$k<=$peak_num_max;$k++)
									{
										$temp_=$pepmod_peak_mz{"$pep#$mod"}+1.007276*($k-1)/$pepmod_peak_charge{"$pep#$mod"};
										print OUT qq!
											x$k <- c($temp_,$temp_)
											lines(y ~ x$k, cex=2, pch=16,  type="p", col=$colors[$k])
										!;
									}
									print OUT qq!text($plot_min_mz,$pepmod_peak_ok_max{"$pep#$mod"}, "$datafile",cex = 1.3,adj = c(0,1))\n!;
									$print_this=1;
								}
							}
							print OUT qq!savePlot(filename="$dir/$pep\_$mod\-mz.png",type="png")\n!;
							close(OUT);
							if ($print_this==1)
							{
								system(qq!"$Rlocation" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
							}
							system(qq!del "R-infile.txt"!);
							#system(qq!del "R-outfile.txt"!);
						}
					}
				}
			}
		}
		close(IN);
		if ($del_text_files!=0)
		{
			system(qq!del "$filename-$peptidelistname.res"!);
		}
		else
		{
			system(qq!move  "$filename-$peptidelistname.res" $dir_!);
		}
	}
}
close(OUT_INTEGRAL);

sub Gaussian
{
	my $time = shift();
	my $time0 = shift();
	my $sigma = shift();
	return exp(-($time-$time0)*($time-$time0)/$sigma/$sigma/2);
}
