#!c:/perl/bin/perl.exe
#
use Statistics::Descriptive;
my $error=0;
my $precursor_mass_error_ppm=25; 
my $precursor_mass_error_da=0.05; 
my $fragment_mass_error_ppm=100;
my $fragment_mass_error_da=0.1;
my $intensity_threshold=0.1;
my $sum_fraction_min=0.5;
my $matched_min=6;
my $threshold="";
my $proton_mass=1.007276;
my $c12_13_mass_diff=1.0033548;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $method=$ARGV[1];} else { $method="1e-3 MS1 MS2"; }
if($method=~/^([0-9\.\-\+edED]+)\s+/)
{
	$threshold=$1;
}
else
{
	$threshold=1e-3;
}
$filename_=$filename;
$filename_=~s/\/([^\/]+)\.xml$//;
my $result_dir=qq!$filename_!;
my $mz_low_mass_cutoff==150;
my $ion_types="by";

if ($error==0)
{
	my @run_names=();
	my %pep_mod=();
	my %rt=();
	my %charge=();
	my %title=();
	my %title_=();
	
	open (IN,"$filename") || die "Could not open $filename\n"; 
	my $reversed=0;
	my $count_ok=0;
	while ($line=<IN>)
	{										
		if ($line=~/\<note type=\"input\" label=\"spectrum\, path\"\>.*\/(.*)\.MGF\<\/note>/i)
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
	}
	@run_names=(@run_names,qq!$MGFfilename!); 
	$count_ok{$MGFfilename}=0;
	close(IN);
	my $data_temp="";
	my $data_temp_="";
	open (IN,"$filename") || die "Could not open $filename\n";
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
		if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*start="([0-9]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
		{
			$id=$1;
			$start=$2;
			$expect=$3;
			$mh=$4;
			$mass_error_da=$5;
			$pep=$6;
			$id_=$id;
			$id_=~s/([0-9]+)\..*$/$1/;
			$mcalc=$mh-$proton_mass;
			$mass=$mcalc+$mass_error_da;
			$mass_error_ppm=$mass_error_da/$mass*1e+6;
			if ($min_mass>$mcalc) { $min_mass=$mcalc; }
			if ($max_mass<$mcalc) { $max_mass=$mcalc; }
			if ($expect<=$threshold)
			{
				if ($reversed==0)
				{
					if (abs($mass_error_ppm)<$precursor_mass_error_ppm)
					{
						$mod_="";
						while($line!~/^\s*\<\/domain\s*\>/)
						{
							$line=<IN>;
							if($line=~/\<aa type\=\".*\" at\=\"(.*)\" modified\=\"(.*)\" \/\>/)
							{
								$mod_loc=$1-$start; 
								$mod_mass=$2;
								$mod_.="$mod_mass\@$mod_loc,";
							}
						}
						$mcalc=calc_pep_mono_mass($pep,$mod_);
						$mass_error_da=$mass-$mcalc;
						$mass_error_ppm=$mass_error_da/$mass*1e+6;
						$data_temp.=qq!#$mass\t$mass_error_da\t$mass_error_ppm#!;
						$data_temp_.=qq!#$pep,$mod_#!;
					}
					else { print qq!Error - mass error larger than $precursor_mass_error_ppm ppm\t$MGFfilename\t$pep\t$mass\t$mass_error_da\t$mass_error_ppm\n!; }
				}
			}
		}  
		if($line=~/<note label=\"Description\">Scan ([0-9]+), Time=([0-9\.0-9]+),([A-Z0-9\,\s]+)\s<\/note>/g)
		{
			$title=qq!Scan $1, Time=$2,$3!;
			$rt{"$MGFfilename#$title"}=$2;
		}
		if($line=~/<GAML:attribute type="charge">(.+?)<\/GAML:attribute>/g)	
		{
			$charge{"$MGFfilename#$title"}=$1; 
			while($data_temp=~s/^#([^#]+)#//)
			{
				my $temp=$1;
				if ($data_temp_=~s/^#([^,]*),([^#]*)#//)
				{
					my $pep=$1;
					my $mod_=$2;
					if ($temp=~/^([^\t]+)\t/)
					{
						my $mass=$1;
						$mz=($mass+$charge{"$MGFfilename#$title"}*1.00727646677)/$charge{"$MGFfilename#$title"};
						$data{"$MGFfilename#$count_ok{$MGFfilename}"}=qq!\t$mz\t$temp!; 
						$title{"$MGFfilename#$title"}="$MGFfilename#$count_ok{$MGFfilename}";
						$title_{"$MGFfilename#$count_ok{$MGFfilename}"}="$MGFfilename#$title"; 
						$pep_mod{"$MGFfilename#$title"}="$pep#$mod_";  
						$count_ok{$MGFfilename}++; 
					}
				}
			}
			$data_temp=""; 
			$data_temp_="";
		}
	}
	close(IN);
	
	open (OUT_LIM1_PPM,">$result_dir/MS1-limits-ppm.txt");
	print OUT_LIM1_PPM qq!name\tcount\tbefore_95\tcal_m_95\tcal_mz_95\tcal_rt_95\tbefore_99\tcal_m_99\tcal_mz_99\tcal_rt_99\n!;
	open (OUT_LIM1_DA,">$result_dir/MS1-limits-da.txt");
	print OUT_LIM1_DA qq!name\tcount\tbefore_95\tcal_m_95\tcal_mz_95\tcal_rt_95\tbefore_99\tcal_m_99\tcal_mz_99\tcal_rt_99\n!;
	open (OUT_LIM2_PPM,">$result_dir/MS2-limits-ppm.txt");
	print OUT_LIM2_PPM qq!name\tcount\tbefore_95\tcal_m_95\tcal_mz_95\tcal_rt_95\tbefore_99\tcal_m_99\tcal_mz_99\tcal_rt_99\n!;
	open (OUT_LIM2_DA,">$result_dir/MS2-limits-da.txt");
	print OUT_LIM2_DA qq!name\tcount\tbefore_95\tcal_m_95\tcal_mz_95\tcal_rt_95\tbefore_99\tcal_m_99\tcal_mz_99\tcal_rt_99\n!;
	my $run_count=0;  
	foreach $run_name (sort @run_names)
	{
		my %tolerances=();
		my %plot_distr_max=();
		print qq!$run_name\n!;

		if (open (IN,"$result_dir/$run_name.mgf"))
		{	
			print qq!$run_name.mgf\n!; 
			#---------------
			#----- MS2 -----
			#---------------
			if (open (OUT,">$result_dir/$run_name-MS2.txt"))
			{
				@mass_to_sort=();
				@mz_to_sort=();
				@rt_to_sort=();
				$to_sort_count=0;
				print OUT qq!rt\tmz\tmass\tmass_error_da\tmass_error_ppm\n!; 
				my $max_intensity=0;
				my @mz=();
				my @intensity=();
				my $points=0;
				my $pepmass="";
				my $title="";
				my $charge="";
				my $rt="";
				my $started_reading_fragments=0;
				my $done_reading_fragments=0;
				while($line=<IN>)
				{   chomp($line);
					if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
					{
						$pepmass=$1; 
					}
					if ($line=~/^TITLE=Scan ([0-9]+), Time=([0-9\.0-9]+),([A-Z0-9\,\s]+)$/)
					{
						$title=qq!Scan $1, Time=$2,$3!; 
						$rt=$2; 
					}
					if ($line=~/^CHARGE=([0-9\.\-\+edED]+)\s*$/)
					{
						$charge=$1;
					}
					if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
					{
						$mz[$points]=$1;
						$intensity[$points]=$2;
						$started_reading_fragments=1; 
						if ($mz_low_mass_cutoff<$mz[$points]-$fragment_mass_error_da)
						{
							if ($min_mz>$mz[$points]) { $min_mz=$mz[$points]; }
							if ($max_mz<$mz[$points]) { $max_mz=$mz[$points]; }
							if ($max_intensity<$intensity[$points]) { $max_intensity=$intensity[$points]; }
							$sum_intensity+=$intensity[$points];
							$points++;
						}
					}
					else
					{
						if ($started_reading_fragments==1)
						{
							$done_reading_fragments=1; 
						}
					}
					if ($done_reading_fragments==1)
					{	
						if ($pep_mod{"$run_name#$title"}=~/^([^#]+)#([^#]*)$/)
						{
							my $pep=$1; 
							my $mod=$2; 
							$rt{"$run_name#$title"}=$rt; 
							$sum_intensity=0;
							my $i=0;
							my $j=0;
							for($i=0,$j=0;$i<$points;$i++)
							{
								if ($intensity_threshold<$intensity[$i]/$max_intensity)
								{
									$intensity[$j]=$intensity[$i];
									$mz[$j]=$mz[$i];
									$sum_intensity+=$intensity[$j];
									$j++;
								}
							}
							$points=$j;
							my $precursor_mz=calc_pep_mono_mz($pep,$charge{"$run_name#$title"},$mod);
							my $delta=($precursor_mz-$pepmass)*$charge{"$run_name#$title"};
							my $delta_=($precursor_mz-$pepmass)/$precursor_mz*1e+6;
							if (abs($precursor_mz-$pepmass)/$precursor_mz<=$precursor_mass_error_ppm/1e+6)
							{
								my $matched="";
								my $sum_fraction="";
								my $max_avg_height="";
								my $avg_height="";
								my $details="";
								my @fragments=();
								fragments(\@fragments,$pep,$mod,$charge{"$run_name#$title"},$ion_types);
								compare_fragments($mz_low_mass_cutoff,$pep,$fragment_mass_error_da,\@fragments,\@mz,\@intensity,$points,$intensity_threshold,
												  $max_intensity,$sum_intensity,\$matched,\$sum_fraction,\$max_avg_height,\$avg_height,\$details);
								if ($sum_fraction>=$sum_fraction_min and $matched>$matched_min)
								{
									while($details=~s/^([^\,]+)\,\s*//)
									{
										my $details_=$1;
										if ($details_=~/^([abcxyc][0-9]+)\s?([0-9]*)\+?\s([0-9\.]+)\s([0-9\.]+)\s([0-9\.\-]+)$/)
										{
											my $ion_type=$1;
											my $charge=$2; 
											my $mz=$3;
											my $mass_error_da=$5;
											if ($charge!~/\w/) { $charge=1;}
											$mass_error_da*=$charge;
											my $mass=($mz-1.007276)*$charge;
											my $mass_error_ppm=$mass_error_da/$mz*1e+6;
											print OUT qq!$rt{"$run_name#$title"}\t$mz\t$mass\t$mass_error_da\t$mass_error_ppm\n!;
											$mass_to_sort[$to_sort_count]="$mass#$mass_error_da#$mass_error_ppm";
											$mz_to_sort[$to_sort_count]="$mz#$mass_error_da#$mass_error_ppm";
											$rt_to_sort[$to_sort_count]=qq!$rt{"$run_name#$title"}#$mass_error_da#$mass_error_ppm!;
											$to_sort_count++;
										}
									}
								}
							}
							else
							{
								print qq!Error - mass error larger than $precursor_mass_error_ppm ppm\t$run_name\t$title\t$pep\t$mod\t$charge{"$run_name#$title"}\t$pepmass\t$precursor_mz\t$delta\t$delta_\n!;
							}
							$max_intensity=0;					
						}
						$max_intensity=0;
						@mz=();
						@intensity=();
						$points=0;
						$pepmass="";
						$title="";
						$charge="";
						$rt="";
						$started_reading_fragments=0;
						$done_reading_fragments=0;
					}
				}
				close(OUT);
			}
			close(IN);
			
			$ms_type="MS2";
			$bin=int($to_sort_count/100); 
			if ($bin<500) { $bin=500; }
			$lower=5;
			$upper=95;
			$factor=1;
			$bin_distr_da=100/$fragment_mass_error_da;
			$bin_distr_ppm=100/$fragment_mass_error_ppm;
			$bin_distr_count=100;
			if (open (OUT,">$result_dir/$run_name-lim-m-MS2.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!mass\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @mass_to_sort;
				for($i=0;$i<$to_sort_count;)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$to_sort_count and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}		
					for($j=0,$k=$i-$bin;$k<$to_sort_count and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-m-distr-da-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!m#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!m#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!m#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!m#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!m#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!m#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!m#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!m#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-m-distr-ppm-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!m#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!m#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!m#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!m#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!m#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!m#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!m#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!m#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}
			
			if (open (OUT,">$result_dir/$run_name-lim-mz-MS2.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!mz\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @mz_to_sort;
				for($i=0;$i<$to_sort_count;)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$to_sort_count and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}	
					for($j=0,$k=$i-$bin;$k<$to_sort_count and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-mz-distr-da-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!mz#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!mz#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!mz#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!mz#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!mz#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!mz#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!mz#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!mz#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-mz-distr-ppm-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!mz#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!mz#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!mz#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!mz#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!mz#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!mz#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!mz#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!mz#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}
			
			if (open (OUT,">$result_dir/$run_name-lim-rt-MS2.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!rt\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @rt_to_sort;
				for($i=0;$i<$to_sort_count;)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$to_sort_count and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}	
					for($j=0,$k=$i-$bin;$k<$to_sort_count and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-rt-distr-da-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!rt#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!rt#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!rt#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!rt#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!rt#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!rt#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!rt#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!rt#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-rt-distr-ppm-MS2.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!rt#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!rt#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!rt#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!rt#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!rt#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!rt#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!rt#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!rt#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}		
			
			#---------------
			#----- MS2 -----
			#---------------
			$ylim="-$fragment_mass_error_ppm,$fragment_mass_error_ppm";
			$xlim="0,$fragment_mass_error_ppm";
			$ms_type="MS2";
			$this="ppm";
			if(open(OUT2,qq!>R-infile.txt!))
			{
				if ($tolerances{"m#$this#$ms_type#95"}!~/\w/) { $tolerances{"m#$this#$ms_type#95"}=$fragment_mass_error_ppm; }
				if ($tolerances{"m#$this#$ms_type#99"}!~/\w/) { $tolerances{"m#$this#$ms_type#99"}=$fragment_mass_error_ppm; }
				if ($tolerances{"m#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#95"}=$fragment_mass_error_ppm; }
				if ($tolerances{"m#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#99"}=$fragment_mass_error_ppm; }
				if ($tolerances{"mz#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#95"}=$fragment_mass_error_ppm; }
				if ($tolerances{"mz#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#99"}=$fragment_mass_error_ppm; }
				if ($tolerances{"rt#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#95"}=$fragment_mass_error_ppm; }
				if ($tolerances{"rt#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#99"}=$fragment_mass_error_ppm; }
				print OUT_LIM2_PPM qq!$run_name\t$run_count!;
				print OUT_LIM2_PPM qq!\t$tolerances{"m#$this#$ms_type#95"}\t$tolerances{"m#$this\_median#$ms_type#95"}\t$tolerances{"mz#$this\_median#$ms_type#95"}\t$tolerances{"rt#$this\_median#$ms_type#95"}!;
				print OUT_LIM2_PPM qq!\t$tolerances{"m#$this#$ms_type#99"}\t$tolerances{"m#$this\_median#$ms_type#99"}\t$tolerances{"mz#$this\_median#$ms_type#99"}\t$tolerances{"rt#$this\_median#$ms_type#99"}!;
				print OUT_LIM2_PPM qq!\n!;
				
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-m-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ mass, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlim=c(500,3500), ylim=c($ylim), xlab="Measured Mass [Da]", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ mass, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-m-$run_name.png",type="png")

							Datafile2 <- read.table("$result_dir/$run_name-lim-m-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							Datafile3 <- read.table("$result_dir/$run_name-lim-mz-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							Datafile4 <- read.table("$result_dir/$run_name-lim-rt-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							plot(after ~ diff, data=Datafile4, type="l", lwd=2, col="red", axes=TRUE, xlim=c($xlim), ylim=c(0,$plot_distr_max{"$this#$ms_type"}), xlab="Mass Error [ppm]", ylab="Number of Peptides", main="$run_name")
							lines(before ~ diff, data=Datafile4, type="l", lwd=2)
							lines(after ~ diff, data=Datafile2, type="l", lwd=2, col="blue")
							lines(after ~ diff, data=Datafile3, type="l", lwd=2, col="olivedrab")
							y<-c(0,0)
							x<-c($tolerances{"m#$this#$ms_type#95"},$tolerances{"m#$this#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2)
							y<-c(-$plot_distr_max{"$this#$ms_type"}/200,-$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"mz#$this\_median#$ms_type#95"},$tolerances{"mz#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="olivedrab")
							y<-c(-2*$plot_distr_max{"$this#$ms_type"}/200,-2*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"m#$this\_median#$ms_type#95"},$tolerances{"m#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="blue")
							y<-c(-3*$plot_distr_max{"$this#$ms_type"}/200,-3*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"rt#$this\_median#$ms_type#95"},$tolerances{"rt#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="red")
							legend("topright", c('before cal','mass cal','m/z','rt cal'), col=c('black','blue','olivedrab','red'), lwd=2)
							savePlot(filename="$result_dir/$ms_type-$this-distr-$run_name.png",type="png")
				!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-mz-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ mz, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="m/z", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ mz, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-ppm-mz-$run_name.png",type="png")
				!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-rt-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ rt, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="Retention Time", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ rt, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-ppm-rt-$run_name.png",type="png")

							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			
			$ylim="-$fragment_mass_error_da,$fragment_mass_error_da";
			$xlim="0,$fragment_mass_error_da";
			$this="da";
			if(open(OUT2,qq!>R-infile.txt!))
			{
				if ($tolerances{"m#$this#$ms_type#95"}!~/\w/) { $tolerances{"m#$this#$ms_type#95"}=$fragment_mass_error_da; }
				if ($tolerances{"m#$this#$ms_type#99"}!~/\w/) { $tolerances{"m#$this#$ms_type#99"}=$fragment_mass_error_da; }
				if ($tolerances{"m#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#95"}=$fragment_mass_error_da; }
				if ($tolerances{"m#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#99"}=$fragment_mass_error_da; }
				if ($tolerances{"mz#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#95"}=$fragment_mass_error_da; }
				if ($tolerances{"mz#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#99"}=$fragment_mass_error_da; }
				if ($tolerances{"rt#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#95"}=$fragment_mass_error_da; }
				if ($tolerances{"rt#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#99"}=$fragment_mass_error_da; }
				print OUT_LIM2_DA qq!$run_name\t$run_count!;
				print OUT_LIM2_DA qq!\t$tolerances{"m#$this#$ms_type#95"}\t$tolerances{"m#$this\_median#$ms_type#95"}\t$tolerances{"mz#$this\_median#$ms_type#95"}\t$tolerances{"rt#$this\_median#$ms_type#95"}!;
				print OUT_LIM2_DA qq!\t$tolerances{"m#$this#$ms_type#99"}\t$tolerances{"m#$this\_median#$ms_type#99"}\t$tolerances{"mz#$this\_median#$ms_type#99"}\t$tolerances{"rt#$this\_median#$ms_type#99"}!;
				print OUT_LIM2_DA qq!\n!;
				
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-m-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_$this ~ mass, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlim=c(500,3500), ylim=c($ylim), xlab="Measured Mass [Da]", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_$this ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_$this ~ mass, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_$this ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-m-$run_name.png",type="png")

							Datafile2 <- read.table("$result_dir/$run_name-lim-m-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							Datafile3 <- read.table("$result_dir/$run_name-lim-mz-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							Datafile4 <- read.table("$result_dir/$run_name-lim-rt-distr-$this-$ms_type.txt", header=TRUE, sep="\t")
							plot(after ~ diff, data=Datafile4, type="l", lwd=2, col="red", axes=TRUE, xlim=c($xlim), ylim=c(0,$plot_distr_max{"$this#$ms_type"}), xlab="Mass Error [Da]", ylab="Number of Peptides", main="$run_name")
							lines(before ~ diff, data=Datafile4, type="l", lwd=2)
							lines(after ~ diff, data=Datafile2, type="l", lwd=2, col="blue")
							lines(after ~ diff, data=Datafile3, type="l", lwd=2, col="olivedrab")
							y<-c(0,0)
							x<-c($tolerances{"m#$this#$ms_type#95"},$tolerances{"m#$this#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2)
							y<-c(-$plot_distr_max{"$this#$ms_type"}/200,-$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"mz#$this\_median#$ms_type#95"},$tolerances{"mz#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="olivedrab")
							y<-c(-2*$plot_distr_max{"$this#$ms_type"}/200,-2*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"m#$this\_median#$ms_type#95"},$tolerances{"m#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="blue")
							y<-c(-3*$plot_distr_max{"$this#$ms_type"}/200,-3*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"rt#$this\_median#$ms_type#95"},$tolerances{"rt#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="red")
							legend("topright", c('before cal','mass cal','m/z cal','rt cal'), col=c('black','blue','olivedrab','red'), lwd=2)
							savePlot(filename="$result_dir/$ms_type-$this-distr-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-mz-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_da ~ mz, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="m/z", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_da ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_da ~ mz, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_da ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-mz-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name-$ms_type.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-rt-$ms_type.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_da ~ rt, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="Retention Time", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_da ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_da ~ rt, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_da ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-rt-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
		}
		
				
		#---------------
		#----- MS1 -----
		#---------------
		if (open (OUT,">$result_dir/$run_name.txt"))
		{
			@mass_to_sort=(); 
			@mz_to_sort=();
			@rt_to_sort=(); 
			print OUT qq!rt\tmz\tmass\tmass_error_da\tmass_error_ppm\n!;  
			for($i=0;$i<$count_ok{$run_name};$i++)
			{
				my $temp=qq!$rt{$title_{"$run_name#$i"}}$data{"$run_name#$i"}!; 
				print OUT qq!$temp\n!;
				if ($temp=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					$mass_to_sort[$i]="$3#$4#$5";
					$mz_to_sort[$i]="$2#$4#$5";
					$rt_to_sort[$i]="$1#$4#$5";
				}
			}
			close(OUT);	
			
			$ms_type="MS1";
			$bin=int($count_ok{$run_name}/50); 
			if ($bin<200) { $bin=200; }
			$lower=5;
			$upper=95;
			$factor=1;
			$bin_distr_da=100/$precursor_mass_error_da;
			$bin_distr_ppm=100/$precursor_mass_error_ppm;
			$bin_distr_count=100;
			if (open (OUT,">$result_dir/$run_name-lim-m.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!mass\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @mass_to_sort;
				for($i=0;$i<$count_ok{$run_name};)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}		
					for($j=0,$k=$i-$bin;$k<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-m-distr-da.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!m#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!m#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!m#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!m#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!m#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!m#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!m#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!m#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-m-distr-ppm.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!m#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!m#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!m#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!m#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!m#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!m#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!m#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!m#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}
			
			if (open (OUT,">$result_dir/$run_name-lim-mz.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!mz\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @mz_to_sort;
				for($i=0;$i<$count_ok{$run_name};)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}	
					for($j=0,$k=$i-$bin;$k<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-mz-distr-da.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!mz#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!mz#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!mz#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!mz#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!mz#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!mz#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!mz#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!mz#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-mz-distr-ppm.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!mz#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!mz#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!mz#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!mz#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!mz#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!mz#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!mz#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!mz#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}
			
			if (open (OUT,">$result_dir/$run_name-lim-rt.txt"))
			{
				@distr_da=();
				@distr_da_median=();
				@distr_ppm=();
				@distr_ppm_median=();
				my $sum_da=0;
				my $sum_da_median=0;
				my $sum_ppm=0;
				my $sum_ppm_median=0;
				print OUT qq!rt\tlower_da\tmedian_da\tupper_da\tlower_ppm\tmedian_ppm\tupper_ppm\n!;
				@sorted = sort { $a <=> $b } @rt_to_sort;
				for($i=0;$i<$count_ok{$run_name};)
				{
					$min=$sorted[$i]; $min=~s/#.*$//;
					@temp_da=();
					@temp_ppm=();
					for($j=0;$i<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$temp_da[$j]=$sorted[$i]; $temp_da[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$2/;
						$temp_ppm[$j]=$sorted[$i]; $temp_ppm[$j]=~s/([^#]+)#([^#]+)#([^#]+)$/$3/;
						$i++;
					}
					$max=$sorted[$i-1]; $max=~s/#.*$//;
					if ($j>=$bin)
					{
						my $stat_da = Statistics::Descriptive::Full->new();
						$stat_da->add_data(@temp_da);
						$median_da=$stat_da->median();
						$upper_da=$stat_da->percentile($upper);
						$lower_da=$stat_da->percentile($lower);
						$upper_da=$median_da+($upper_da-$median_da)*$factor;
						$lower_da=$median_da-($median_da-$lower_da)*$factor;
						my $stat_ppm = Statistics::Descriptive::Full->new();
						$stat_ppm->add_data(@temp_ppm);
						$median_ppm=$stat_ppm->median();
						$upper_ppm=$stat_ppm->percentile($upper);
						$lower_ppm=$stat_ppm->percentile($lower);
						$upper_ppm=$median_ppm+($upper_ppm-$median_ppm)*$factor;
						$lower_ppm=$median_ppm-($median_ppm-$lower_ppm)*$factor;
					}	
					for($j=0,$k=$i-$bin;$k<$count_ok{$run_name} and $j<$bin;$j++)
					{
						$n=int($bin_distr_da*abs($temp_da[$j])); if ($n<=$bin_distr_count) { $distr_da[$n]++; $sum_da++; }
						$n=int($bin_distr_da*abs($temp_da[$j]-$median_da)); if ($n<=$bin_distr_count) { $distr_da_median[$n]++; $sum_da_median++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j])); if ($n<=$bin_distr_count) { $distr_ppm[$n]++; $sum_ppm++; }
						$n=int($bin_distr_ppm*abs($temp_ppm[$j]-$median_ppm)); if ($n<=$bin_distr_count) { $distr_ppm_median[$n]++; $sum_ppm_median++; }
						$k++;
					}
					print OUT qq!$min\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
					print OUT qq!$max\t$lower_da\t$median_da\t$upper_da\t$lower_ppm\t$median_ppm\t$upper_ppm\n!;
				}
				close(OUT);
				if (open (OUT,">$result_dir/$run_name-lim-rt-distr-da.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_da[$k]!~/\w/) { $distr_da[$k]=0; }
						if ($distr_da_median[$k]!~/\w/) { $distr_da_median[$k]=0; }
						$diff=$k/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$diff=($k+1)/$bin_distr_da;
						print OUT qq!$diff\t$distr_da[$k]\t$distr_da_median[$k]\n!;
						$sum_+=$distr_da[$k];
						$sum_median+=$distr_da_median[$k];
						$limit=95;
						if ($tolerances{qq!rt#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!rt#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!rt#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!rt#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						$limit=99;
						if ($tolerances{qq!rt#da#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_da) { $tolerances{qq!rt#da#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if ($tolerances{qq!rt#da_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_da_median) { $tolerances{qq!rt#da_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_da; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da[$k]; }
						if($plot_distr_max{"da#$ms_type"}<$distr_da_median[$k]) { $plot_distr_max{"da#$ms_type"}=$distr_da_median[$k]; }
					}
					close(OUT);
				}
				if (open (OUT,">$result_dir/$run_name-lim-rt-distr-ppm.txt"))
				{
					my $sum_=0;
					my $sum_median=0;
					print OUT qq!diff\tbefore\tafter\n!;
					print OUT qq!0\t0\t0\n!;
					for($k=0;$k<=$bin_distr_count;$k++)
					{
						if ($distr_ppm[$k]!~/\w/) { $distr_ppm[$k]=0; }
						if ($distr_ppm_median[$k]!~/\w/) { $distr_ppm_median[$k]=0; }
						$diff=$k/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$diff=($k+1)/$bin_distr_ppm;
						print OUT qq!$diff\t$distr_ppm[$k]\t$distr_ppm_median[$k]\n!;
						$sum_+=$distr_ppm[$k];
						$sum_median+=$distr_ppm_median[$k];
						$limit=95;
						if ($tolerances{qq!rt#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!rt#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!rt#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!rt#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						$limit=99;
						if ($tolerances{qq!rt#ppm#$ms_type#$limit!}!~/\w/ and $sum_>=$limit/100*$sum_ppm) { $tolerances{qq!rt#ppm#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if ($tolerances{qq!rt#ppm_median#$ms_type#$limit!}!~/\w/ and $sum_median>=$limit/100*$sum_ppm_median) { $tolerances{qq!rt#ppm_median#$ms_type#$limit!}=($k+0.5)/$bin_distr_ppm; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm[$k]; }
						if($plot_distr_max{"ppm#$ms_type"}<$distr_ppm_median[$k]) { $plot_distr_max{"ppm#$ms_type"}=$distr_ppm_median[$k]; }
					}
					close(OUT);
				}
			}
					
			#---------------
			#----- MS1 -----
			#---------------
			$ylim="-$precursor_mass_error_ppm,$precursor_mass_error_ppm";
			$xlim="0,$precursor_mass_error_ppm";
			$ms_type="MS1";
			$this="ppm";
			if(open(OUT2,qq!>R-infile.txt!))
			{
				if ($tolerances{"m#$this#$ms_type#95"}!~/\w/) { $tolerances{"m#$this#$ms_type#95"}=$fragment_mass_error_ppm; }
				if ($tolerances{"m#$this#$ms_type#99"}!~/\w/) { $tolerances{"m#$this#$ms_type#99"}=$fragment_mass_error_ppm; }
				if ($tolerances{"m#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#95"}=$precursor_mass_error_ppm; }
				if ($tolerances{"m#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#99"}=$precursor_mass_error_ppm; }
				if ($tolerances{"mz#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#95"}=$precursor_mass_error_ppm; }
				if ($tolerances{"mz#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#99"}=$precursor_mass_error_ppm; }
				if ($tolerances{"rt#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#95"}=$precursor_mass_error_ppm; }
				if ($tolerances{"rt#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#99"}=$precursor_mass_error_ppm; }
				print OUT_LIM1_PPM qq!$run_name\t$run_count!;
				print OUT_LIM1_PPM qq!\t$tolerances{"m#$this#$ms_type#95"}\t$tolerances{"m#$this\_median#$ms_type#95"}\t$tolerances{"mz#$this\_median#$ms_type#95"}\t$tolerances{"rt#$this\_median#$ms_type#95"}!;
				print OUT_LIM1_PPM qq!\t$tolerances{"m#$this#$ms_type#99"}\t$tolerances{"m#$this\_median#$ms_type#99"}\t$tolerances{"mz#$this\_median#$ms_type#99"}\t$tolerances{"rt#$this\_median#$ms_type#99"}!;
				print OUT_LIM1_PPM qq!\n!;
				
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-m.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ mass, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlim=c(500,3500), ylim=c($ylim), xlab="Measured Mass [Da]", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ mass, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-m-$run_name.png",type="png")

							Datafile2 <- read.table("$result_dir/$run_name-lim-m-distr-$this.txt", header=TRUE, sep="\t")
							Datafile3 <- read.table("$result_dir/$run_name-lim-mz-distr-$this.txt", header=TRUE, sep="\t")
							Datafile4 <- read.table("$result_dir/$run_name-lim-rt-distr-$this.txt", header=TRUE, sep="\t")
							plot(after ~ diff, data=Datafile4, type="l", lwd=2, col="red", axes=TRUE, xlim=c($xlim), ylim=c(0,$plot_distr_max{"ppm#$ms_type"}), xlab="Mass Error [ppm]", ylab="Number of Peptides", main="$run_name")
							lines(before ~ diff, data=Datafile4, type="l", lwd=2)
							lines(after ~ diff, data=Datafile2, type="l", lwd=2, col="blue")
							lines(after ~ diff, data=Datafile3, type="l", lwd=2, col="olivedrab")
							y<-c(0,0)
							x<-c($tolerances{"m#$this#$ms_type#95"},$tolerances{"m#$this#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2)
							y<-c(-$plot_distr_max{"$this#$ms_type"}/200,-$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"mz#$this\_median#$ms_type#95"},$tolerances{"mz#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="olivedrab")
							y<-c(-2*$plot_distr_max{"$this#$ms_type"}/200,-2*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"m#$this\_median#$ms_type#95"},$tolerances{"m#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="blue")
							y<-c(-3*$plot_distr_max{"$this#$ms_type"}/200,-3*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"rt#$this\_median#$ms_type#95"},$tolerances{"rt#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="red")
							legend("topright", c('before cal','mass cal','m/z','rt cal'), col=c('black','blue','olivedrab','red'), lwd=2)
							savePlot(filename="$result_dir/$ms_type-$this-distr-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-mz.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ mz, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="m/z", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ mz, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-ppm-mz-$run_name.png",type="png")
				!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-rt.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_ppm ~ rt, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="Retention Time", ylab="Mass Error [ppm]", main="$run_name")
							lines(lower_ppm ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_ppm ~ rt, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_ppm ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-ppm-rt-$run_name.png",type="png")

							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			
			$ylim="-$precursor_mass_error_da,$precursor_mass_error_da";
			$xlim="0,$precursor_mass_error_da";
			$this="da";
			if(open(OUT2,qq!>R-infile.txt!))
			{
				if ($tolerances{"m#$this#$ms_type#95"}!~/\w/) { $tolerances{"m#$this#$ms_type#95"}=$fragment_mass_error_da; }
				if ($tolerances{"m#$this#$ms_type#99"}!~/\w/) { $tolerances{"m#$this#$ms_type#99"}=$fragment_mass_error_da; }
				if ($tolerances{"m#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#95"}=$precursor_mass_error_da; }
				if ($tolerances{"m#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"m#$this\_median#$ms_type#99"}=$precursor_mass_error_da; }
				if ($tolerances{"mz#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#95"}=$precursor_mass_error_da; }
				if ($tolerances{"mz#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"mz#$this\_median#$ms_type#99"}=$precursor_mass_error_da; }
				if ($tolerances{"rt#$this\_median#$ms_type#95"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#95"}=$precursor_mass_error_da; }
				if ($tolerances{"rt#$this\_median#$ms_type#99"}!~/\w/) { $tolerances{"rt#$this\_median#$ms_type#99"}=$precursor_mass_error_da; }
				print OUT_LIM1_DA qq!$run_name\t$run_count!;
				print OUT_LIM1_DA qq!\t$tolerances{"m#$this#$ms_type#95"}\t$tolerances{"m#$this\_median#$ms_type#95"}\t$tolerances{"mz#$this\_median#$ms_type#95"}\t$tolerances{"rt#$this\_median#$ms_type#95"}!;
				print OUT_LIM1_DA qq!\t$tolerances{"m#$this#$ms_type#99"}\t$tolerances{"m#$this\_median#$ms_type#99"}\t$tolerances{"mz#$this\_median#$ms_type#99"}\t$tolerances{"rt#$this\_median#$ms_type#99"}!;
				print OUT_LIM1_DA qq!\n!;
				
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-m.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_da ~ mass, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, xlim=c(500,3500), ylim=c($ylim), xlab="Measured Mass [Da]", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_da ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_da ~ mass, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_da ~ mass, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-$this-m-$run_name.png",type="png")

							Datafile2 <- read.table("$result_dir/$run_name-lim-m-distr-$this.txt", header=TRUE, sep="\t")
							Datafile3 <- read.table("$result_dir/$run_name-lim-mz-distr-$this.txt", header=TRUE, sep="\t")
							Datafile4 <- read.table("$result_dir/$run_name-lim-rt-distr-$this.txt", header=TRUE, sep="\t")
							plot(after ~ diff, data=Datafile4, type="l", lwd=2, col="red", axes=TRUE, xlim=c($xlim), ylim=c(0,$plot_distr_max{"$this#$ms_type"}), xlab="Mass Error [Da]", ylab="Number of Peptides", main="$run_name")
							lines(before ~ diff, data=Datafile4, type="l", lwd=2)
							lines(after ~ diff, data=Datafile2, type="l", lwd=2, col="blue")
							lines(after ~ diff, data=Datafile3, type="l", lwd=2, col="olivedrab")
							y<-c(0,0)
							x<-c($tolerances{"m#$this#$ms_type#95"},$tolerances{"m#$this#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2)
							y<-c(-$plot_distr_max{"$this#$ms_type"}/200,-$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"mz#$this\_median#$ms_type#95"},$tolerances{"mz#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="olivedrab")
							y<-c(-2*$plot_distr_max{"$this#$ms_type"}/200,-2*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"m#$this\_median#$ms_type#95"},$tolerances{"m#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="blue")
							y<-c(-3*$plot_distr_max{"$this#$ms_type"}/200,-3*$plot_distr_max{"$this#$ms_type"}/200)
							x<-c($tolerances{"rt#$this\_median#$ms_type#95"},$tolerances{"rt#$this\_median#$ms_type#99"})
							lines(y ~ x, type="p", pch=16, cex=2, col="red")
							legend("topright", c('before cal','mass cal','m/z cal','rt cal'), col=c('black','blue','olivedrab','red'), lwd=2)
							savePlot(filename="$result_dir/$ms_type-$this-distr-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-mz.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_da ~ mz, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="m/z", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_da ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_da ~ mz, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_da ~ mz, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-da-mz-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
			
			if(open(OUT2,qq!>R-infile.txt!))
			{
				print OUT2 qq!windows(width=8, height=8)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.8,0.5,0.2))
							par(font=1)
							Datafile <- read.table("$result_dir/$run_name.txt", header=TRUE, sep="\t")
							Datafile1 <- read.table("$result_dir/$run_name-lim-rt.txt", header=TRUE, sep="\t")
							attach(Datafile)
							plot(mass_error_da ~ rt, data=Datafile, pch=20, cex=0.1, type="p", axes=TRUE, ylim=c($ylim), xlab="Retention Time", ylab="Mass Error [Da]", main="$run_name")
							lines(lower_da ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							lines(median_da ~ rt, data=Datafile1, type="l", lwd=2, col="red")
							lines(upper_da ~ rt, data=Datafile1, type="l", lwd=1, col="red")
							savePlot(filename="$result_dir/$ms_type-da-rt-$run_name.png",type="png")
							!;
				close(OUT2);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}
		}
		$run_count++;
		
	}
	close(OUT_LIM1_PPM);
	close(OUT_LIM1_DA);
	close(OUT_LIM2_PPM);
	close(OUT_LIM2_DA);
	
	system(qq!del "$result_dir\\*-distr-ppm-MS2.txt"!);
	system(qq!del "$result_dir\\*-distr-ppm.txt"!);
	system(qq!del "$result_dir\\*-distr-da-MS2.txt"!);
	system(qq!del "$result_dir\\*-distr-da.txt"!);
}


sub calc_pep_mono_mass
{
	my $peptide = shift();
	my $modifications = shift();
	my $mass=0.0;
	my $err=0;
	my %atom_masses=();
	my %molecule_masses=();
	my %aa_masses=();

	my $proton_mass=1.007276;
	$atom_masses{"H"}=1.007825035;
	$atom_masses{"O"}=15.99491463;
	$atom_masses{"N"}=14.003074;
	$atom_masses{"C"}=12.0;
	$atom_masses{"S"}=31.9720707;
	$atom_masses{"P"}=30.973762;

	$molecule_masses{"H2O"}=2*$atom_masses{"H"} + $atom_masses{"O"};
	$molecule_masses{"NH3"} = $atom_masses{"N"} + 3*$atom_masses{"H"};
	$molecule_masses{"HPO3"} = $atom_masses{"H"} + $atom_masses{"P"} + 3*$atom_masses{"O"};
	$molecule_masses{"H3PO4"} = 3*$atom_masses{"H"} + $atom_masses{"P"} + 4*$atom_masses{"O"};

	sub calc_aa_mono_mass
	{
		my $composition = shift();
		my $mass=0.0;
		while ($composition=~s/^([A-Z][a-z]?)([0-9]*)//)
		{
			my $atom=$1;
			my $number=$2;
			if ($number!~/\w/) { $number=1; }
			$mass += $number*$atom_masses{$atom};
		}
		return $mass;	
	}

	$aa_masses{'A'} = calc_aa_mono_mass("C3H5ON");
	$aa_masses{'B'} = calc_aa_mono_mass("C4H6O2N2");	# Same as N
	$aa_masses{'C'} = calc_aa_mono_mass("C3H5ONS");
	$aa_masses{'D'} = calc_aa_mono_mass("C4H5O3N");
	$aa_masses{'E'} = calc_aa_mono_mass("C5H7O3N");
	$aa_masses{'F'} = calc_aa_mono_mass("C9H9ON");
	$aa_masses{'G'} = calc_aa_mono_mass("C2H3ON");
	$aa_masses{'H'} = calc_aa_mono_mass("C6H7ON3");
	$aa_masses{'I'} = calc_aa_mono_mass("C6H11ON");
	$aa_masses{'K'} = calc_aa_mono_mass("C6H12ON2");
	$aa_masses{'L'} = calc_aa_mono_mass("C6H11ON");
	$aa_masses{'M'} = calc_aa_mono_mass("C5H9ONS");
	$aa_masses{'N'} = calc_aa_mono_mass("C4H6O2N2");
	$aa_masses{'P'} = calc_aa_mono_mass("C5H7ON");
	$aa_masses{'Q'} = calc_aa_mono_mass("C5H8O2N2");
	$aa_masses{'R'} = calc_aa_mono_mass("C6H12ON4");
	$aa_masses{'S'} = calc_aa_mono_mass("C3H5O2N");
	$aa_masses{'T'} = calc_aa_mono_mass("C4H7O2N");
	$aa_masses{'V'} = calc_aa_mono_mass("C5H9ON");
	$aa_masses{'W'} = calc_aa_mono_mass("C11H10ON2");
	$aa_masses{'Y'} = calc_aa_mono_mass("C9H9O2N");
	$aa_masses{'Z'} = calc_aa_mono_mass("C5H8O2N2");	# Same as Q

	if ($peptide!~/\w/)
	{
		my $aa="";
		foreach $aa (sort keys %aa_masses)
		{
			print qq!$aa\t$aa_masses{$aa}\n!;
		}
	}
	else
	{
		while ($peptide=~/\w/ and $err==0)
		{
			if ($peptide=~s/^([A-Z])//) { $mass+=$aa_masses{$1}; } else { $err=1; }
		}
		$mass+=$molecule_masses{"H2O"};
		my %modifications=(); 
		while($modifications=~s/^([^\@]+)\@([^\,]+)//)
		{
			my $mod_location=$2;
			my $mod_mass=$1;
			if($mod_mass!~/^([0-9\-\+])/) 
			{ 
				$mod_mass=calc_mono_mass_frag($mod_mass); 
			}
			$mass+=$mod_mass;
			$modifications=~s/^\,//;
		}
	}
	if ($err==0) { return $mass; } else { return -1; }
}

sub calc_pep_mono_mz
{
	my $peptide = shift();
	my $charge = shift();
	my $modifications = shift();

	my $proton_mass=1.007276;
	my $mass = calc_pep_mono_mass($peptide,$modifications)/$charge + $proton_mass;

	return $mass;
}

sub calc_pep_mono_MH 
{
	my $peptide = shift();
	my $modifications = shift();

	my $proton_mass=1.007276;
	my $mass = calc_pep_mono_mass($peptide,$modifications) + $proton_mass;

	return $mass;
}

sub fragments 
{
	my $fragments = shift();
	my $peptide = shift();
    my $modifications = shift();
	my $charge = shift();
    my $ion_types = shift();
	my $mass=0.0;
	my $err=0;
	my $aa="";
	my %atom_masses=();
	my %molecule_masses=();
	my %aa_masses=();
	@$fragments=();

	if ($ion_types!~/\w/) { $ion_types = "by"; }

	my $proton_mass=1.007276;
	$atom_masses{"H"}=1.007825035;
	$atom_masses{"O"}=15.99491463;
	$atom_masses{"N"}=14.003074;
	$atom_masses{"C"}=12.0;
	$atom_masses{"S"}=31.9720707;
	$atom_masses{"P"}=30.973762;

	$molecule_masses{"H2O"}=2*$atom_masses{"H"} + $atom_masses{"O"};
	$molecule_masses{"NH3"} = $atom_masses{"N"} + 3*$atom_masses{"H"};
	$molecule_masses{"HPO3"} = $atom_masses{"H"} + $atom_masses{"P"} + 3*$atom_masses{"O"};
	$molecule_masses{"H3PO4"} = 3*$atom_masses{"H"} + $atom_masses{"P"} + 4*$atom_masses{"O"};
	
	my @neutral_losses=("",);
	
	sub calc_mono_mass_frag
	{
		my $composition = shift();
		my $mass=0.0;
		while ($composition=~s/^([A-Z][a-z]?)([0-9]*)//)
		{
			my $atom=$1;
			my $number=$2;
			if ($number!~/\w/) { $number=1; }
			$mass += $number*$atom_masses{$atom};
		}
		return $mass;	
	}

	$aa_masses{'A'} = calc_mono_mass_frag("C3H5ON");
	$aa_masses{'B'} = calc_mono_mass_frag("C4H6O2N2");	# Same as N
	$aa_masses{'C'} = calc_mono_mass_frag("C3H5ONS");
	$aa_masses{'D'} = calc_mono_mass_frag("C4H5O3N");
	$aa_masses{'E'} = calc_mono_mass_frag("C5H7O3N");
	$aa_masses{'F'} = calc_mono_mass_frag("C9H9ON");
	$aa_masses{'G'} = calc_mono_mass_frag("C2H3ON");
	$aa_masses{'H'} = calc_mono_mass_frag("C6H7ON3");
	$aa_masses{'I'} = calc_mono_mass_frag("C6H11ON");
	$aa_masses{'K'} = calc_mono_mass_frag("C6H12ON2");
	$aa_masses{'L'} = calc_mono_mass_frag("C6H11ON");
	$aa_masses{'M'} = calc_mono_mass_frag("C5H9ONS");
	$aa_masses{'N'} = calc_mono_mass_frag("C4H6O2N2");
	$aa_masses{'P'} = calc_mono_mass_frag("C5H7ON");
	$aa_masses{'Q'} = calc_mono_mass_frag("C5H8O2N2");
	$aa_masses{'R'} = calc_mono_mass_frag("C6H12ON4");
	$aa_masses{'S'} = calc_mono_mass_frag("C3H5O2N");
	$aa_masses{'T'} = calc_mono_mass_frag("C4H7O2N");
	$aa_masses{'V'} = calc_mono_mass_frag("C5H9ON");
	$aa_masses{'W'} = calc_mono_mass_frag("C11H10ON2");
	$aa_masses{'Y'} = calc_mono_mass_frag("C9H9O2N");
	$aa_masses{'Z'} = calc_mono_mass_frag("C5H8O2N2");	# Same as Q

	my %modifications=(); 
	while($modifications=~s/^([^\@]+)\@([^\,]+)//)
	{
		my $mod_location=$2;
		my $mod_mass=$1;
		if($mod_mass!~/^([0-9\-\+])/) 
		{ 
			$mod_mass=calc_mono_mass_frag($mod_mass); 
		}
		$modifications{$mod_location}=$mod_mass;
		$modifications=~s/^\,//;
	}

	my %ions=();
	$ions{"b"} = $atom_masses{"H"};
	$ions{"c"} = $atom_masses{"N"} + 4*$atom_masses{"H"};
	$ions{"y"} = 3*$atom_masses{"H"} + $atom_masses{"O"};
	$ions{"z"} = 3*$atom_masses{"H"} + $atom_masses{"O"} - 2*$atom_masses{"H"} - $atom_masses{"N"};

	while($ion_types=~s/^([bcyz])//)
	{
		my $ion_type=$1;
		$mass=$ions{$ion_type};
		my $peptide_ = $peptide;
		if ($ion_type=~/[abc]/)
		{
			my $index=0;
			while ($peptide_=~s/^([A-Z])//)
			{
				$aa=$1;
				$mass+=$aa_masses{$aa};
				$mass+=$modifications{$aa};
				$mass+=$modifications{$index};
				my $index__=$index+1;
				foreach my $neutral_loss (@neutral_losses)
				{
					for(my $charge_=1;$charge_<$charge or $charge_==1;$charge_++)
					{
						my $mass_=($mass-$molecule_masses{$neutral_loss}+($charge_-1)*$proton_mass)/$charge_;
						my $temp=""; 
						if ($neutral_loss=~/\w/) { $temp.=" -$neutral_loss"; }
						if ($charge_>1) { $temp.=" $charge_+"; }
						@$fragments=(@$fragments,"$mass_ ($ion_type$index__$temp)");
					}
				}
				$index++;
			}
		}
		else
		{
			my $index=length($peptide)-1;
			while ($peptide_=~s/([A-Z])$//)
			{
				$aa=$1;
				$mass+=$aa_masses{$aa};
				$mass+=$modifications{$aa};
				$mass+=$modifications{$index};
				my $index__=length($peptide)-$index;
				foreach my $neutral_loss (@neutral_losses)
				{
					for(my $charge_=1;$charge_<$charge or $charge_==1;$charge_++)
					{
						my $mass_=($mass-$molecule_masses{$neutral_loss}+($charge_-1)*$proton_mass)/$charge_;
						my $temp=""; 
						if ($neutral_loss=~/\w/) { $temp.=" -$neutral_loss"; }
						if ($charge_>1) { $temp.=" $charge_+"; }
						@$fragments=(@$fragments,"$mass_ ($ion_type$index__$temp)");
					}
				}
				$index--;
			}
		}
	}
	if ($err==0) { return 1; } else { return ""; }
}

sub compare_fragments
{
	my $mz_low_mass_cutoff = shift();
	my $pep = shift();
	my $mass_error = shift();
	my $fragments = shift();
	my $spectrum_mz = shift();
	my $spectrum_int = shift();
	my $spectrum_count = shift();
	my $intensity_threshold = shift();
	my $max_intensity = shift();
	my $sum_intensity = shift();
	my $matched = shift();
	my $sum_fraction = shift();
	my $max_avg_height = shift();
	my $avg_height = shift();
	my $details = shift();

	my @fragments_ = sort { $a <=> $b } @$fragments;
	my $count_matched_b=0;
	my $count_matched_y=0;
	my $height_all_matched=0;
	my $intensity_sum_all_matched=0;
	my $j=0;
	my $jj=0;
	my @used=();

	for($j=0;$fragments_[$j]=~/\w/;$j++)
	{
		my $frag_mass=$fragments_[$j]; $frag_mass=~s/^([0-9\.edED\-\+]+)\s.*$/$1/;
		if ($mz_low_mass_cutoff<$frag_mass-$mass_error)
		{
			my $frag_mass_=$frag_mass;
			my $frag_type=$fragments_[$j]; $frag_type=~s/^([0-9\.edED\-\+]+)\s\(?(.*)\)$/$2/;
			my $residue=-1;
			if ($frag_type=~/^([a-z]+)([0-9]+)$/) { $residue=$2-1; if ($frag_type=~/^[xyz]/) { $residue=length($pep)-1-($residue+1); } }
			my $intensity_max=0;
			my $intensity_sum=0;
			my $delta_mass=0;
			$jj=0;
			my $intensity_max_=0;
			my $intensity_sum_=0;
			my $min_error=10000;
			for(;@$spectrum_mz[$jj]>$frag_mass_-$mass_error and $jj>0;$jj--) { ; }
			for(;@$spectrum_mz[$jj]<$frag_mass_-$mass_error and $jj<$spectrum_count;$jj++) { ; }
			for(;abs($frag_mass_-@$spectrum_mz[$jj])<$mass_error and $jj<$spectrum_count;$jj++) 
			{
				if ($intensity_threshold<@$spectrum_int[$jj]/$max_intensity and $used[$jj]!~/\w/)
				{
					$used[$jj]=1;
					if (abs($min_error)>abs($frag_mass_-@$spectrum_mz[$jj])) { $min_error=@$spectrum_mz[$jj]-$frag_mass_; }
					if ($intensity_max_<@$spectrum_int[$jj]) { $intensity_max_=@$spectrum_int[$jj]; }
					$intensity_sum_+=@$spectrum_int[$jj];
					$intensity_sum_all_matched+=@$spectrum_int[$jj];
				}
			}
			if ($intensity_max_>0)
			{
				if ($intensity_max<$intensity_max_) { $intensity_max=$intensity_max_; }
				$intensity_sum+=$intensity_sum_;
				$height_all_matched+=$intensity_sum_/$max_intensity;
				if ($$max_avg_height<$intensity_sum_/$max_intensity) { $$max_avg_height=$intensity_sum_/$max_intensity; }
				my $temp=$frag_mass*100+0.5; $temp=~s/\..*$//; $temp/=100;
				my $temp_=$intensity_max_*100+0.5; $temp_=~s/\..*$//; $temp_/=100;
				$$details.="$frag_type $temp $temp_ $min_error, ";
			}
			if ($intensity_max>0) 
			{ 
				if($frag_type=~/^abc/) { $count_matched_b++; } else { $count_matched_y++; } 
			}
		}
	}
	$$matched=$count_matched_b+$count_matched_y;
	if ($$matched>0) { $$avg_height=$height_all_matched/$$matched; }
	if ($sum_intensity>0) { $$sum_fraction=$intensity_sum_all_matched/$sum_intensity; }
}
