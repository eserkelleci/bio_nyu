#!c:/Perl/bin/perl.exe

use strict;

my $error=0;
my $filename="";
my $filename_control="";
my $expect_threshold=-2;
my $filename_normalization="";

# The input files are the Excel outputs of X! Tandem results
if ($ARGV[0]=~/\w/) { $filename="$ARGV[0]"; } else { $error=1; }
if ($ARGV[1]=~/\w/) { $filename_control="$ARGV[1]"; } else { $error=1; }
if ($ARGV[2]=~/\w/) { $expect_threshold="$ARGV[2]"; } else { $expect_threshold=-2; }
if ($ARGV[3]=~/\w/) { $filename_normalization="$ARGV[3]"; } else { $filename_normalization="normalization-cai.txt"; }

my $plot_coverage=0;
$filename=~s/\\/\//g;
$filename_control=~s/\\/\//g;
my $line="";

if ($error==0)
{
	my %norm=();
	my @norm=();
	my $norm_count=0;
	my $norm_min=10000000000000;
	my $dist_min=10000000000000;
	my $norm_max=0;
	my $norm_median=0;
	if (open(IN,"$filename_normalization"))
	{
		$line=<IN>;
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)/)
			{
				my $name=$1;
				my $norm=$2;
				if ($norm=~/^[0-9\.\+\-edED]+$/ and $norm=~/[0-9]/)
				{
					$norm{$name}=$norm;
					$norm[$norm_count++]=$norm;
					if ($norm_max<$norm) { $norm_max=$norm; }
					if ($norm_min>$norm) { $norm_min=$norm; }
				}
			}
		}
		my @norm_sorted = sort { $a <=> $b } @norm;
		$norm_median=$norm_sorted[int($norm_count/2)];
		for(my $i=1;$i<$norm_count;$i++)
		{
			if($dist_min>($norm_sorted[$i]-$norm_sorted[$i-1]) and 0<($norm_sorted[$i]-$norm_sorted[$i-1])) { $dist_min=($norm_sorted[$i]-$norm_sorted[$i-1])}
		}
		if ($norm_min<=0)
		{
			foreach my $key (keys %norm)
			{
				$norm{$key}=$norm{$key}-$norm_min+$dist_min;
			}
		}
	}
	print qq!Normalization: $norm_count, $norm_median ($norm_min,$norm_max) $dist_min\n!;
	
	my %crosslinked=();
	my @crosslinked=();
	my @crosslinked_spectrum_count=();
	my @crosslinked_norm=();
	my @crosslinked_norm_spectrum_count=();
	my @crosslinked_expect=();
	my $crosslinked_count=0;
	if (open(IN,"$filename"))
	{
		$line=<IN>;
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $expect=$2;
				my $coverage=$5;
				my $spectrum_count=$7;
				my $ac=$9;
				$crosslinked{$ac}=$line;
				my $norm=$norm_median;
				if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
				my $coverage_norm=$coverage/$norm;
				my $spectrum_count_norm=$spectrum_count/$norm;
				if ($expect<=$expect_threshold)
				{
					$crosslinked[$crosslinked_count]="$coverage#$line";
					$crosslinked_spectrum_count[$crosslinked_count]="$spectrum_count#$line";
					$crosslinked_norm[$crosslinked_count]="$coverage_norm#$line";
					$crosslinked_norm_spectrum_count[$crosslinked_count]="$spectrum_count_norm#$line";
					$crosslinked_count++;
				}
			}
			else
			{
				if ($line=~/\w/) { print qq!Error ($filename): $line\n!; }
			}
		}
		close(IN);
	}
	my @crosslinked_sorted = sort { $b <=> $a } @crosslinked;
	my @crosslinked_spectrum_count_sorted = sort { $b <=> $a } @crosslinked_spectrum_count;	
	my @crosslinked_norm_sorted = sort { $b <=> $a } @crosslinked_norm;
	my @crosslinked_norm_spectrum_count_sorted = sort { $b <=> $a } @crosslinked_norm_spectrum_count;
	
	my %control=();
	my @control=();
	my @control_spectrum_count=();
	my @control_norm=();
	my @control_norm_spectrum_count=();
	my $control_count=0;
	if (open(IN,"$filename_control"))
	{
		$line=<IN>;
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $expect=$2;
				my $coverage=$5;
				my $spectrum_count=$7;
				my $ac=$9;
				$control{$ac}=$line;
				my $norm=$norm_median;
				if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
				my $coverage_norm=$coverage/$norm;
				my $spectrum_count_norm=$spectrum_count/$norm;
				if ($expect<=$expect_threshold)
				{
					$control[$control_count]="$coverage#$line";
					$control_spectrum_count[$control_count]="$spectrum_count#$line";
					$control_norm[$control_count]="$coverage_norm#$line";
					$control_norm_spectrum_count[$control_count]="$spectrum_count_norm#$line";
					$control_count++;
				}
			}
			else
			{
				if ($line=~/\w/) { print qq!Error ($filename_control): $line\n!; }
			}
		}
		close(IN);
	}
	my @control_sorted = sort { $b <=> $a } @control;
	my @control_spectrum_count_sorted = sort { $b <=> $a } @control_spectrum_count;
	my @control_norm_sorted = sort { $b <=> $a } @control_norm;
	my @control_norm_spectrum_count_sorted = sort { $b <=> $a } @control_norm_spectrum_count;
	
	
	
	#----------------#
	# Coverage plots #
	#----------------#
	if ($plot_coverage==1)
	{
		if (open(OUT,">$filename-coverage.txt"))
		{
			my $coverage_max=0;
			my $coverage_norm_max=0;
			print OUT qq!rank\tcoverage\tcoverage_control\tname\n!;
			my $i_=0;
			for(my $i=0;$i<$crosslinked_count;$i++)
			{
				if ($crosslinked_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					my $coverage=$5;
					my $ac=$9;
					my $desc=$10;
					$desc=~s/^\s+//;
					$coverage=~s/\s*\+\s*$//;
					if ($coverage_max<$coverage) { $coverage_max=$coverage; }
					my $coverage_control=0;
					if ($control{$ac}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
					{
						$coverage_control=$5;
						$coverage_control=~s/\s*\+\s*$//;
						if ($coverage_max<$coverage_control) { $coverage_max=$coverage_control; }
					}
					my $name="";
					if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
					print OUT qq!$i_\t$coverage\t$coverage_control\t$name\n!;
					$i_++;
				}
			}
			close(OUT);
			
			open(OUT,">$filename-coverage-normalized.txt");
			print OUT qq!rank\tcoverage\tcoverage_control\tname\n!;
			my $i_=0;
			for(my $i=0;$i<$crosslinked_count;$i++)
			{
				if ($crosslinked_norm_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					my $coverage=$5;
					my $ac=$9;
					my $desc=$10;
					$desc=~s/^\s+//;
					$coverage=~s/\s*\+\s*$//;
					my $norm=$norm_median;
					if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
					$coverage/=$norm;
					if ($coverage_norm_max<$coverage) { $coverage_norm_max=$coverage; }
					my $coverage_control=0;
					if ($control{$ac}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
					{
						$coverage_control=$5;
						$coverage_control=~s/\s*\+\s*$//;
						$coverage_control/=$norm;
						if ($coverage_norm_max<$coverage_control) { $coverage_norm_max=$coverage_control; }
					}
					my $name="";
					if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
					print OUT qq!$i_\t$coverage\t$coverage_control\t$name\n!;
					$i_++;
				}
			}
			close(OUT);

			if(open(OUT,qq!>R-infile.txt!))
			{
				print OUT qq!windows(width=8, height=11)
							par(tcl=0.2)
							par(mfrow=c(2,1))
							par(mai=c(0.8,0.8,0.1,0.1))
							par(font=1)
							Datafile <- read.table("$filename-coverage.txt", header=TRUE, sep="\t")
							attach(Datafile)
							
							plot(coverage ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$coverage_max), pch=16, cex=2, xlab="Rank", ylab="Coverage (corrected)", col="red", type="p")
							text(rank, 1.05*$coverage_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							lines(coverage_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
							
							plot(coverage ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.4*$coverage_max), pch=16, cex=2, xlab="Rank", ylab="Coverage (corrected)", col="red", type="p")
							text(rank, 1.05*$coverage_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							lines(coverage_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
							
				!;
				print OUT qq!savePlot(filename="$filename-coverage-top50.png",type="png")!;
				close(OUT);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				#system(qq!del R-infile.txt!);
				#system(qq!del R-outfile.txt!);
			}
		

			if(open(OUT,qq!>R-infile.txt!))
			{
				print OUT qq!windows(width=8, height=11)
							par(tcl=0.2)
							par(mfrow=c(2,1))
							par(mai=c(0.8,0.8,0.1,0.1))
							par(font=1)
							Datafile <- read.table("$filename-coverage-normalized.txt", header=TRUE, sep="\t")
							attach(Datafile)
							
							plot(coverage ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$coverage_norm_max), pch=16, cex=2, xlab="Rank", ylab="Coverage (corrected)", col="red", type="p")
							text(rank, 1.05*$coverage_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							lines(coverage_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
							
							plot(coverage ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.40*$coverage_norm_max), pch=16, cex=2, xlab="Rank", ylab="Coverage (corrected)", col="red", type="p")
							text(rank, 1.05*$coverage_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							lines(coverage_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
				!;
				print OUT qq!savePlot(filename="$filename-coverage-normalized-top50.png",type="png")!;
				close(OUT);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				#system(qq!del R-infile.txt!);
				#system(qq!del R-outfile.txt!);
			}
		}
		
		if (open(OUT,">$filename_control-coverage-control.txt"))
		{
			my $coverage_max=0;
			my $coverage_norm_max=0;
			print OUT qq!rank\tcoverage\tname\n!;
			my $i_=0;
			for(my $i=0;$i<$control_count;$i++)
			{
				if ($control_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					my $coverage=$5;
					my $ac=$9;
					my $desc=$10;
					$desc=~s/^\s+//;
					$coverage=~s/\s*\+\s*$//;
					if ($coverage_max<$coverage) { $coverage_max=$coverage; }
					my $name="";
					if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
					print OUT qq!$i_\t$coverage\t$name\n!;
					$i_++;
				}
			}
			close(OUT);
			open(OUT,">$filename_control-coverage-control-normalized.txt");
			print OUT qq!rank\tcoverage\tname\n!;
			my $i_=0;
			for(my $i=0;$i<$control_count;$i++)
			{
				if ($control_norm_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					my $coverage=$5;
					my $ac=$9;
					my $desc=$10;
					$desc=~s/^\s+//;
					$coverage=~s/\s*\+\s*$//;
					my $norm=$norm_median;
					if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
					$coverage/=$norm;
					if ($coverage_norm_max<$coverage) { $coverage_norm_max=$coverage; }
					my $name="";
					if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
					print OUT qq!$i_\t$coverage\t$name\n!;
					$i_++;
				}
			}
			close(OUT);

			if(open(OUT,qq!>R-infile.txt!))
			{
				print OUT qq!windows(width=8, height=11)
							par(tcl=0.2)
							par(mfrow=c(2,1))
							par(mai=c(0.8,0.8,0.1,0.1))
							par(font=1)
							Datafile <- read.table("$filename_control-coverage-control.txt", header=TRUE, sep="\t")
							attach(Datafile)
							
							plot(coverage ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.40*$coverage_max), pch=17, cex=1.7, xlab="Rank", ylab="Coverage (corrected)", col="black", type="p")
							text(rank, 1.05*$coverage_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							
							plot(coverage ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.40*$coverage_max), pch=17, cex=1.7, xlab="Rank", ylab="Coverage (corrected)", col="black", type="p")
							text(rank, 1.05*$coverage_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							
				!;
				print OUT qq!savePlot(filename="$filename_control-coverage-control-top50.png",type="png")!;
				close(OUT);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				#system(qq!del R-infile.txt!);
				#system(qq!del R-outfile.txt!);
			}
			if(open(OUT,qq!>R-infile.txt!))
			{
				print OUT qq!windows(width=8, height=11)
							par(tcl=0.2)
							par(mfrow=c(2,1))
							par(mai=c(0.8,0.8,0.1,0.1))
							par(font=1)
							Datafile <- read.table("$filename_control-coverage-control-normalized.txt", header=TRUE, sep="\t")
							attach(Datafile)
							
							plot(coverage ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.40*$coverage_norm_max), pch=17, cex=1.7, xlab="Rank", ylab="Coverage (corrected)", col="black", type="p")
							text(rank, 1.05*$coverage_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							
							plot(coverage ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.40*$coverage_norm_max), pch=17, cex=1.7, xlab="Rank", ylab="Coverage (corrected)", col="black", type="p")
							text(rank, 1.05*$coverage_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
							
				!;
				print OUT qq!savePlot(filename="$filename_control-coverage-control-normalized-top50.png",type="png")!;
				close(OUT);
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				#system(qq!del R-infile.txt!);
				#system(qq!del R-outfile.txt!);
			}
		}
	}
	
	
	#----------------------#
	# Spectrum count plots #
	#----------------------#
	if (open(OUT,">$filename-spectrum-count.txt"))
	{
		my $spectrum_count_max=0;
		my $spectrum_count_norm_max=0;
		print OUT qq!rank\tspectrum_count\tspectrum_count_control\tname\n!;
		my $i_=0;
		for(my $i=0;$i<$crosslinked_count;$i++)
		{
			if ($crosslinked_spectrum_count_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $spectrum_count=$7;
				my $ac=$9;
				my $desc=$10;
				if ($spectrum_count_max<$spectrum_count) { $spectrum_count_max=$spectrum_count; }
				$desc=~s/^\s+//;
				my $spectrum_count_control=0;
				if ($control{$ac}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					$spectrum_count_control=$7;
					if ($spectrum_count_max<$spectrum_count_control) { $spectrum_count_max=$spectrum_count_control; }
				}
				my $name="";
				if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
				print OUT qq!$i_\t$spectrum_count\t$spectrum_count_control\t$name\n!;
				$i_++;
			}
		}
		close(OUT);

		open(OUT,">$filename-spectrum-count-normalized.txt");
		print OUT qq!rank\tspectrum_count\tspectrum_count_control\tname\n!;
		my $i_=0;
		for(my $i=0;$i<$crosslinked_count;$i++)
		{
			if ($crosslinked_norm_spectrum_count_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $spectrum_count=$7;
				my $ac=$9;
				my $desc=$10;
				my $norm=$norm_median;
				if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
				$spectrum_count/=$norm;
				if ($spectrum_count_norm_max<$spectrum_count) { $spectrum_count_norm_max=$spectrum_count; }
				$desc=~s/^\s+//;
				my $spectrum_count_control=0;
				if ($control{$ac}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
				{
					$spectrum_count_control=$7;
					$spectrum_count_control/=$norm;
					if ($spectrum_count_norm_max<$spectrum_count_control) { $spectrum_count_norm_max=$spectrum_count_control; }
				}
				my $name="";
				if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
				print OUT qq!$i_\t$spectrum_count\t$spectrum_count_control\t$name\n!;
				$i_++;
			}
		}
		close(OUT);

		if(open(OUT,qq!>R-infile.txt!))
		{
			print OUT qq!windows(width=8, height=11)
						par(tcl=0.2)
						par(mfrow=c(2,1))
						par(mai=c(0.8,0.8,0.1,0.1))
						par(font=1)
						Datafile <- read.table("$filename-spectrum-count.txt", header=TRUE, sep="\t")
						attach(Datafile)
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$spectrum_count_max), pch=16, cex=2, xlab="Rank", ylab="Spectrum Count", col="red", type="p")
						text(rank, 1.05*$spectrum_count_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						lines(spectrum_count_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.4*$spectrum_count_max), pch=16, cex=2, xlab="Rank", ylab="Spectrum Count", col="red", type="p")
						text(rank, 1.05*$spectrum_count_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						lines(spectrum_count_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
						
			!;
			print OUT qq!savePlot(filename="$filename-spectrum-count-top50.png",type="png")!;
			close(OUT);
			system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			#system(qq!del R-infile.txt!);
			#system(qq!del R-outfile.txt!);
		}
	

		if(open(OUT,qq!>R-infile.txt!))
		{
			print OUT qq!windows(width=8, height=11)
						par(tcl=0.2)
						par(mfrow=c(2,1))
						par(mai=c(0.8,0.8,0.1,0.1))
						par(font=1)
						Datafile <- read.table("$filename-spectrum-count-normalized.txt", header=TRUE, sep="\t")
						attach(Datafile)
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$spectrum_count_norm_max), pch=16, cex=2, xlab="Rank", ylab="Spectrum Count", col="red", type="p")
						text(rank, 1.05*$spectrum_count_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						lines(spectrum_count_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.4*$spectrum_count_norm_max), pch=16, cex=2, xlab="Rank", ylab="Spectrum Count", col="red", type="p")
						text(rank, 1.05*$spectrum_count_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						lines(spectrum_count_control ~ rank, data=Datafile, pch=17, cex=1.7, type="p")
			!;
			print OUT qq!savePlot(filename="$filename-spectrum-count-normalized-top50.png",type="png")!;
			close(OUT);
			system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			#system(qq!del R-infile.txt!);
			#system(qq!del R-outfile.txt!);
		}
	}
	
	if (open(OUT,">$filename_control-spectrum-count-control.txt"))
	{
		my $spectrum_count_max=0;
		my $spectrum_count_norm_max=0;
		print OUT qq!rank\tspectrum_count\tname\n!;
		my $i_=0;
		for(my $i=0;$i<$control_count;$i++)
		{
			if ($control_spectrum_count_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $spectrum_count=$7;
				my $ac=$9;
				my $desc=$10;
				if ($spectrum_count_max<$spectrum_count) { $spectrum_count_max=$spectrum_count; }
				$desc=~s/^\s+//;
				my $name="";
				if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
				print OUT qq!$i_\t$spectrum_count\t$name\n!;
				$i_++;
			}
		}
		close(OUT);

		open(OUT,">$filename_control-spectrum-count-control-normalized.txt");
		print OUT qq!rank\tspectrum_count\tname\n!;
		my $i_=0;
		for(my $i=0;$i<$control_count;$i++)
		{
			if ($control_norm_spectrum_count_sorted[$i]=~/^[^#]+#([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $spectrum_count=$7;
				my $ac=$9;
				my $desc=$10;
				my $norm=$norm_median;
				if ($norm{$ac}=~/\w/) { $norm=$norm{$ac}; }
				$spectrum_count/=$norm;
				if ($spectrum_count_norm_max<$spectrum_count) { $spectrum_count_norm_max=$spectrum_count; }
				$desc=~s/^\s+//;
				my $name="";
				if ($ac=~/_/) { $name=$ac; } else { $name=$desc; $name=~s/ .*$//; $name=~s/\s*,\s*$//; }
				print OUT qq!$i_\t$spectrum_count\t$name\n!;
				$i_++;
			}
		}
		close(OUT);
		
		if(open(OUT,qq!>R-infile.txt!))
		{
			print OUT qq!windows(width=8, height=11)
						par(tcl=0.2)
						par(mfrow=c(2,1))
						par(mai=c(0.8,0.8,0.1,0.1))
						par(font=1)
						Datafile <- read.table("$filename_control-spectrum-count-control.txt", header=TRUE, sep="\t")
						attach(Datafile)
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$spectrum_count_max), pch=17, cex=1.7, xlab="Rank", ylab="Spectrum Count", col="black", type="p")
						text(rank, 1.05*$spectrum_count_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.4*$spectrum_count_max), pch=17, cex=1.7, xlab="Rank", ylab="Spectrum Count", col="black", type="p")
						text(rank, 1.05*$spectrum_count_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						
			!;
			print OUT qq!savePlot(filename="$filename_control-spectrum-count-control-top50.png",type="png")!;
			close(OUT);
			system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			#system(qq!del R-infile.txt!);
			#system(qq!del R-outfile.txt!);
		}
		if(open(OUT,qq!>R-infile.txt!))
		{
			print OUT qq!windows(width=8, height=11)
						par(tcl=0.2)
						par(mfrow=c(2,1))
						par(mai=c(0.8,0.8,0.1,0.1))
						par(font=1)
						Datafile <- read.table("$filename_control-spectrum-count-control-normalized.txt", header=TRUE, sep="\t")
						attach(Datafile)
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(0,24), ylim=c(0,1.4*$spectrum_count_norm_max), pch=17, cex=1.7, xlab="Rank", ylab="Spectrum Count", col="black", type="p")
						text(rank, 1.05*$spectrum_count_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						
						plot(spectrum_count ~ rank, data=Datafile, xlim=c(25,49), ylim=c(0,1.4*$spectrum_count_norm_max), pch=17, cex=1.7, xlab="Rank", ylab="Spectrum Count", col="black", type="p")
						text(rank, 1.05*$spectrum_count_norm_max, name, cex=1, adj=c(0,0.35), srt=90, col="black")
						
			!;
			print OUT qq!savePlot(filename="$filename_control-spectrum-count-control-normalized-top50.png",type="png")!;
			close(OUT);
			system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			system(qq!del R-infile.txt!);
			system(qq!del R-outfile.txt!);
		}
	}
}