sub numerically { $a <=> $b }
sub numericallydesc { $b <=> $a; }
use strict;

require "./common_phospho_mgf.pl";

my $dir="";
my $mass_error="";
my $intensity_threshold_spectrum="";
my $ascore_mass_bin_size="";
my $ascore_peaks_per_bin="";

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="data"; }
if ($ARGV[1]=~/\w/) { $mass_error=$ARGV[1];} else { $mass_error=0.5; }
if ($ARGV[2]=~/\w/) { $intensity_threshold_spectrum=$ARGV[2];} else { $intensity_threshold_spectrum=0.01; }
if ($ARGV[3]=~/\w/) { $ascore_mass_bin_size=$ARGV[3];} else { $ascore_mass_bin_size=100; }
if ($ARGV[4]=~/\w/) { $ascore_peaks_per_bin=$ARGV[4];} else { $ascore_peaks_per_bin=6; }

if (opendir(dir,"$dir"))
{
	my @alldirs=readdir dir;
	closedir dir;
	foreach my $dir_ (@alldirs)
	{
		if (open(IN,"$dir/$dir_-localize_phospho_mgf.log"))
		{
			my $line="";
			while($line=<IN>)
			{
				if ($line=~/^(\S+)\s+(\S*)\s+([^\@]+)\@([^\#]+)#(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)$/)
				{
					my $pep=$1;
					my $modifications_fixed=$2;
					my $mod_mass=$3;
					my $modifications_ori=$6;
					my $charge=$7;
					my $mz=$8;
					my $scan=$9;
					my $scoring=$10;
					my $filename="$pep\_$modifications_ori\_$charge\_$mz\_$scan";
					my $modifications="";
					my @labels={};
					my @ions={};
					my @data=();
					my $data_count=0;
					while($line=~/\w/)
					{
						$line=<IN>;
						if ($scoring=~/ascore/)
						{
							if ($line=~/^(\S+)\s+(\S+)\.\s+(\S+)\s*\(?([^\-]*)\-?(\S*)\)?\s*\[([0-9]+)b,([0-9]+)y,([0-9]+)bgr\]\s*\(([^\)]+)\)/)
							{
								my $mods=$1;
								my $rank=$2;
								my $score=$3;
								my $diff=$5-$4;
								my $num_b=$6;
								my $num_y=$7;
								my $num_bgr=$8;
								my $ions=$9;
								if ($diff!~/\w/) { $diff=0; }
								$data[$data_count]=qq!$diff#$mods#$num_b#$num_y#$num_bgr#$ions!;
								$data_count++;
							}
						}
					}
					if ($data_count>0)
					{
						my @data_sorted = sort numerically @data;
						#print qq!$pep\n!;
						my $rank=0;
						my $previous_diff=-1;
						for(my $i=0;$i<$data_count;$i++)
						{
							my $diff=0;
							my $mods="";
							my $modifications_this=$modifications_fixed;
							if ($data_sorted[$i]=~/^([^#]+)#([^#]+)#([^#]+)#([^#]+)#([^#]+)#(.*)$/)
							{
								$diff=$1;
								$mods=$2;
								my $num_b=$3;
								my $num_y=$4;
								my $num_backgr=$5;
								my $ions=$6;
								my $mods_="";
								my $temp=$mods;
								my $index=0;
								$rank++;
								if ($rank<=5)
								{
									while($temp=~s/^([01])//)
									{
										if ($1==1) { $modifications_this.=$mod_mass . "\@" . $index . ","; $mods_.="."; } else { $mods_.=" "; }
										$index++;
									}
									if ($previous_diff<$diff) { $modifications.="\*$modifications_this\*"; }
									$labels[$rank].="$mods_,";
									$ions[$rank]=$ions;
								}
							}
							$previous_diff=$diff;
						}
					}
					if ($modifications=~/\w/)
					{
						my @spectrum_mz=();
						my @spectrum_int=();
						my $spectrum_count=0;
						my $max_intensity=0;
						my $sum_intensity=0;
						read_mgf_ascore("$dir/$dir_/localization/$filename.mgf",$mass_error,$ascore_mass_bin_size,$ascore_peaks_per_bin,$mz,$charge,\@spectrum_mz,\@spectrum_int,\$spectrum_count,\$max_intensity,\$sum_intensity);
						make_spectrum_plot_("$dir/$dir_/localization/$filename",\@spectrum_mz,\@spectrum_int,$spectrum_count,\@ions,$pep,$modifications,\@labels,$charge,$max_intensity,$sum_intensity);
					}
				}
			}
		}
	}
}
