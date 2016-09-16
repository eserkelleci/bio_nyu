#!/usr/local/bin/perl

use Statistics::Descriptive;
use strict;

my $error=0;
my $dir="";
my $pep_mod_charge_norm="";
if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $pep_mod_charge_norm="$ARGV[1]";} else { $pep_mod_charge_norm="YAASSYLSLTPEQWK##2"; }

my $factor=1;

if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @alldirs=readdir dir;
		closedir dir;
		my %dirs=();
		my %pepmod=();
		my %data=();
		my %data_min=();
		my %data_max=();
		my %ok=();
		my %count=();
		my %count_all=();
		my $count=0;
		my $scan_max=0;
		foreach my $dir_ (@alldirs)
		{
			if ($dir_=~/\w/)
			{				
				if (opendir(dir,"$dir/$dir_"))
				{
					closedir dir;
					if (open(IN,"$dir/$dir_/integral.txt"))
					{
						$dirs{$dir_}=1;
						if ($dir_=~/^([^\.]+)[\.]/)
						{
							my $key=$1;
							$key=~s/([0-9]+)$//;
							$count_all{"$key"}++;
							print qq!$dir_\n!;
							my $line=<IN>;
							while($line=<IN>)
							{
								if ($line=~/^([^\t]+)\t([^\t]*)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$/)
								{
									my $pep=$1;
									my $mod=$2;
									my $charge=$3;
									my $integral=$4;
									my $min=$5;
									my $max=$6;
									my $width=$7;
									if ($pepmod{"$pep#$mod"}!~/#$charge#/) { $pepmod{"$pep#$mod"}.="#$charge#"; }
									$data{"$dir_#$pep#$mod#$charge"}=$integral;
									$data_min{"$dir_#$pep#$mod#$charge"}=$min;
									$data_max{"$dir_#$pep#$mod#$charge"}=$max;
									if ($scan_max<$max) { $scan_max=$max; }
									$count{"$key#$pep#$mod#$charge"}++;
								}
								else
								{
									if ($line=~/\w/) { print qq!Error parsing: $line\n!; }
								}
							}
							$count++;
						} else { print qq!Error: $dir_\n!; }
						close(IN);
					}
				}
			}
		}
		
		
		if (open(OUT,">$dir/compare_std.txt"))
		{
			print OUT qq!pep\tmod\tcharge\tstd_log\tstd_lognorm\n!;
			foreach my $pepmod (sort keys %pepmod)
			{
				if ($pepmod=~/^([^#]+)#([^#]*)$/)
				{
					my $pep=$1;
					my $mod=$2;
					my $temp=$pepmod{"$pep#$mod"};
					for(my $charge=1;$charge<=4;$charge++)
					{
						if ($temp=~/#$charge#/)
						{
							$ok{"$pep#$mod#$charge"}=0;
							foreach my $dir_ (sort keys %dirs)
							{
								if ($dir_=~/^([^\.]+)[\.]/)
								{
									my $key=$1;
									$key=~s/([0-9]+)$//;
									if ($count{"$key#$pep#$mod#$charge"}>=$factor*$count_all{"$key"}) { $ok{"$pep#$mod#$charge"}=1; }
								}
							}
							if ($ok{"$pep#$mod#$charge"}==1)
							{
								my @data_log=();
								my $data_log_count=0;
								my @data_lognorm=();
								my $data_lognorm_count=0;
								foreach my $dir_ (sort keys %dirs)
								{
									if ($data{"$dir_#$pep#$mod#$charge"}>0) 
									{
										my $log=log($data{"$dir_#$pep#$mod#$charge"})/log(10);
										$data_log[$data_log_count++]=$log;
										my $lognorm=$log;
										if ($data{"$dir_#$pep_mod_charge_norm"}>0) 
										{ 
											$lognorm-=log($data{"$dir_#$pep_mod_charge_norm"})/log(10); 
											$data_lognorm[$data_lognorm_count++]=$lognorm;
										}
									}
								}
								my $stat_log = Statistics::Descriptive::Full->new();
								$stat_log->add_data(@data_log); 
								my $avg_log = $stat_log->mean();
								my $std_log = $stat_log->standard_deviation();
								#if ($avg_log!=0) { $std_log/=$avg_log; } else { $std_log=-1; }
								my $stat_lognorm = Statistics::Descriptive::Full->new();
								$stat_lognorm->add_data(@data_lognorm); 
								my $avg_lognorm = $stat_lognorm->mean();
								my $std_lognorm = $stat_lognorm->standard_deviation();
								#if ($avg_lognorm!=0) { $std_lognorm/=abs($avg_lognorm); } else { $std_lognorm=-1; }
								print OUT qq!$pep\t$mod\t$charge\t$std_log\t$std_lognorm\n!;
							}
						}
					}
				}
			}
			close(OUT);
		}
		my $axis="";
		my $axis_max=0;
		open(OUTN,">$dir/compare_norm.txt");
		open(OUTMIN,">$dir/compare_min.txt");
		open(OUTMAX,">$dir/compare_max.txt");
		if (open(OUT,">$dir/compare.txt"))
		{
			print OUT qq!name\tnumber!;
			print OUTN qq!name\tnumber!;
			print OUTMIN qq!name\tnumber!;
			print OUTMAX qq!name\tnumber!;
			foreach my $pepmod (sort keys %pepmod)
			{
				if ($pepmod=~/^([^#]+)#([^#]*)$/)
				{
					my $pep=$1;
					my $mod=$2;
					my $temp=$pepmod{"$pep#$mod"};
					for(my $charge=1;$charge<=4;$charge++)
					{
						if ($temp=~/#$charge#/)
						{
							if ($ok{"$pep#$mod#$charge"}==1)
							{
								print OUT qq!\t$pep\_$mod\_$charge!;
								print OUTN qq!\t$pep\_$mod\_$charge!;
								print OUTMIN qq!\t$pep\_$mod\_$charge!;
								print OUTMAX qq!\t$pep\_$mod\_$charge!;
							}
						}
					}
				}
			}
			print OUT qq!\n!;
			print OUTN qq!\n!;
			print OUTMIN qq!\n!;
			print OUTMAX qq!\n!;
			my $number=1;
			foreach my $dir_ (sort keys %dirs)
			{
				if ($dir_=~/^([^\.]+)[\.]/)
				{
					my $key=$1;
					$axis.=qq!\"$key\",!;
					$axis_max++;
				}
				print OUT qq!$dir_\t$number!;
				print OUTN qq!$dir_\t$number!;
				print OUTMIN qq!$dir_\t$number!;
				print OUTMAX qq!$dir_\t$number!;
				foreach my $pepmod (sort keys %pepmod)
				{
					if ($pepmod=~/^([^#]+)#([^#]*)$/)
					{
						my $pep=$1;
						my $mod=$2;
						my $temp=$pepmod{"$pep#$mod"};
						for(my $charge=1;$charge<=4;$charge++)
						{
							if ($temp=~/#$charge#/)
							{
								if ($ok{"$pep#$mod#$charge"}==1)
								{
									if ($data{"$dir_#$pep#$mod#$charge"}<=0) { $data{"$dir_#$pep#$mod#$charge"}=1; }
									my $log=log($data{"$dir_#$pep#$mod#$charge"})/log(10);
									my $lognorm=$log;
									if ($data{"$dir_#$pep_mod_charge_norm"}>0) { $lognorm-=log($data{"$dir_#$pep_mod_charge_norm"})/log(10); } else { $lognorm=0; }
									print OUT qq!\t$log!;
									print OUTN qq!\t$lognorm!;
									print OUTMIN qq!\t$data_min{"$dir_#$pep#$mod#$charge"}!;
									print OUTMAX qq!\t$data_max{"$dir_#$pep#$mod#$charge"}!;
								}
							}
						}
					}
				}
				print OUT qq!\n!;
				print OUTN qq!\n!;
				print OUTMIN qq!\n!;
				print OUTMAX qq!\n!;
				$number++;
			}
			close(OUT);
		}
		close(OUTN);
		close(OUTMIN);
		close(OUTMAX);
		
		
		open(OUT_HTML,qq!>$dir/compare.html!);
		foreach my $pepmod (sort keys %pepmod)
		{
			if ($pepmod=~/^([^#]+)#([^#]*)$/)
			{
				my $pep=$1;
				my $mod=$2;
				my $temp=$pepmod{"$pep#$mod"};
				if(open(OUT,qq!>R-infile.txt!))
				{
					print OUT qq!windows(width=8, height=8)
								par(tcl=0.2)
								par(mfrow=c(1,1))
								par(mai=c(0.9,0.8,0.5,0.2))
								par(font=1)
								Datafile <- read.table("$dir/compare.txt", header=TRUE, sep="\t")
								Datafile_norm <- read.table("$dir/compare_norm.txt", header=TRUE, sep="\t")
					!;
					my $first=1;
					my @colors=("","black","blue","red","olivedrab");
					my $legend_c="";
					my $legend_pch="";
					my $legend_col="";
					for(my $charge=1;$charge<=4;$charge++)
					{
						if ($temp=~/#$charge#/)
						{
							if ($ok{"$pep#$mod#$charge"}==1)
							{
								if ($first==1)
								{
									$first=0;
									print OUT qq!plot($pep\_$mod\_$charge ~ number, data=Datafile, pch=20, cex=4, type="p", col="$colors[$charge]", axes=FALSE, ylim=c(3,10), xlab="", ylab="log10(Intensity)", main="$pep $mod")\n!;
									$axis=~s/\,$//;
									print OUT qq!box()\naxis(2, lab=T)\naxis(1, at=1:$axis_max, lab=c($axis))\n!;
								}
								else
								{
									print OUT qq!lines($pep\_$mod\_$charge ~ number, data=Datafile, pch=20, cex=4, type="p", col="$colors[$charge]")\n!;
								}
								$legend_c.="\'$charge\+\',";
								$legend_pch.="20,";
								$legend_col.="\'$colors[$charge]\',";
							}
						}
					}
					if ($legend_c=~/\w/)
					{
						$legend_c=~s/,$//;
						$legend_pch=~s/,$//;
						$legend_col=~s/,$//;
						print OUT qq!legend("topleft",c($legend_c), pch=c($legend_pch), cex=1, pt.cex = 2, col=c($legend_col),ncol=1)\n!;
					}
					print OUT qq!savePlot(filename="$dir/int-$pep\_$mod.png",type="png")!;
					close(OUT);
					if ($first==0)
					{
						system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
						print OUT_HTML qq!<img src="int-$pep\_$mod.png" height="325" width="325" />!;
						#system(qq!del R-outfile.txt!);
					}
					system(qq!del R-infile.txt!);
				}
				if(open(OUT,qq!>R-infile.txt!))
				{
					print OUT qq!windows(width=8, height=8)
								par(tcl=0.2)
								par(mfrow=c(1,1))
								par(mai=c(0.9,0.8,0.5,0.2))
								par(font=1)
								Datafile <- read.table("$dir/compare.txt", header=TRUE, sep="\t")
								Datafile_norm <- read.table("$dir/compare_norm.txt", header=TRUE, sep="\t")
					!;
					my $first=1;
					my @colors=("","black","blue","red","olivedrab");
					my $legend_c="";
					my $legend_pch="";
					my $legend_col="";
					for(my $charge=1;$charge<=4;$charge++)
					{
						if ($temp=~/#$charge#/)
						{
							if ($ok{"$pep#$mod#$charge"}==1)
							{
								if ($first==1)
								{
									$first=0;
									print OUT qq!plot($pep\_$mod\_$charge ~ number, data=Datafile_norm, pch=20, cex=4, type="p", col="$colors[$charge]", axes=FALSE, ylim=c(-5,2), xlab="", ylab="Normalized log10(Intensity)", main="$pep $mod")\n!;
									$axis=~s/\,$//;
									print OUT qq!box()\naxis(2, lab=T)\naxis(1, at=1:$axis_max, lab=c($axis))\n!;
								}
								else
								{
									print OUT qq!lines($pep\_$mod\_$charge ~ number, data=Datafile_norm, pch=20, cex=4, type="p", col="$colors[$charge]")\n!;
								}
								$legend_c.="\'$charge\+\',";
								$legend_pch.="20,";
								$legend_col.="\'$colors[$charge]\',";
							}
						}
					}
					if ($legend_c=~/\w/)
					{
						$legend_c=~s/,$//;
						$legend_pch=~s/,$//;
						$legend_col=~s/,$//;
						print OUT qq!legend("topleft",c($legend_c), pch=c($legend_pch), cex=1, pt.cex = 2, col=c($legend_col),ncol=1)\n!;
					}
					print OUT qq!savePlot(filename="$dir/norm-$pep\_$mod.png",type="png")!;
					close(OUT);
					if ($first==0)
					{
						system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
						print OUT_HTML qq!<img src="norm-$pep\_$mod.png" height="325" width="325" />!;
						print OUT_HTML qq!<br><br><br>\n!;
						#system(qq!del R-outfile.txt!);
					}
					system(qq!del R-infile.txt!);
				}
				
				
				if(open(OUT,qq!>R-infile.txt!))
				{
					print OUT qq!windows(width=8, height=8)
								par(tcl=0.2)
								par(mfrow=c(1,1))
								par(mai=c(0.9,0.8,0.5,0.2))
								par(font=1)
								Datafile_min <- read.table("$dir/compare_min.txt", header=TRUE, sep="\t")
								Datafile_max <- read.table("$dir/compare_max.txt", header=TRUE, sep="\t")
					!;
					my $first=1;
					my @colors=("","black","blue","red","olivedrab");
					my $legend_c="";
					my $legend_pch="";
					my $legend_col="";
					for(my $charge=1;$charge<=4;$charge++)
					{
						if ($temp=~/#$charge#/)
						{
							if ($ok{"$pep#$mod#$charge"}==1)
							{
								if ($first==1)
								{
									$first=0;
									print OUT qq!plot($pep\_$mod\_$charge ~ number, data=Datafile_min, pch=20, cex=4, type="p", col="$colors[$charge]", axes=FALSE, ylim=c(0,$scan_max), xlab="", ylab="scan", main="$pep $mod")\n!;
									$axis=~s/\,$//;
									print OUT qq!box()\naxis(2, lab=T)\naxis(1, at=1:$axis_max, lab=c($axis))\n!;
									print OUT qq!lines($pep\_$mod\_$charge ~ number, data=Datafile_max, pch=20, cex=4, type="p", col="$colors[$charge]")\n!;
								}
								else
								{
									print OUT qq!lines($pep\_$mod\_$charge ~ number, data=Datafile_min, pch=20, cex=4, type="p", col="$colors[$charge]")\n!;
									print OUT qq!lines($pep\_$mod\_$charge ~ number, data=Datafile_max, pch=20, cex=4, type="p", col="$colors[$charge]")\n!;
								}
								$legend_c.="\'$charge\+\',";
								$legend_pch.="20,";
								$legend_col.="\'$colors[$charge]\',";
							}
						}
					}
					if ($legend_c=~/\w/)
					{
						$legend_c=~s/,$//;
						$legend_pch=~s/,$//;
						$legend_col=~s/,$//;
						print OUT qq!legend("topleft",c($legend_c), pch=c($legend_pch), cex=1, pt.cex = 2, col=c($legend_col),ncol=1)\n!;
					}
					print OUT qq!savePlot(filename="$dir/range-$pep\_$mod.png",type="png")!;
					close(OUT);
					if ($first==0)
					{
						system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
						#system(qq!del R-outfile.txt!);
					}
					system(qq!del R-infile.txt!);
				}
			}
		}
		close(OUT_HTML);
	}
}

