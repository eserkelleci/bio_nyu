#!/usr/local/bin/perl
#

use strict;

my $error=0;
my $dir="";

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $error=1; }

if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		my $count=0;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/^([A-Z]+)\-0?\-z([0-9]+)\.txt$/i)
			{
				my $pep=$1;
				my $z=$2;
				if (open(IN,"$dir/$filename"))
				{
					my $peaks_count=0;
					my %scans=();
					print qq!$filename\n!;
					my %light=();
					my $line=<IN>;
					chomp($line);
					if ($line=~s/^([^\t]+)\t//)
					{
						while ($line=~s/^mz([0-9]+)\tint([0-9]+)\t//) { $peaks_count++; }
					}
					while($line=<IN>)
					{
						chomp($line);
						if ($line=~s/^([^\t]+)\t//)
						{
							my $scan=$1;
							if ($line=~s/\t([^\t]+)$//)
							{
								my $ok=$1;
								if ($ok>0)
								{
									for(my $i=0;$i<$peaks_count;$i++)
									{
										if ($line=~s/^([^\t]+)\t([^\t]+)\t//)
										{
											$light{qq!$scan#$i!}=$2;
											$scans{qq!$scan!}=1;
										}
									}
								}
							}
						}
					}
					close(IN);
					if (open(IN,"$dir/$pep-Heavy-z$z.txt"))
					{
						my %heavy=();
						$peaks_count=0;
						$line=<IN>;
						chomp($line);
						if ($line=~s/^([^\t]+)\t//)
						{
							while ($line=~s/^mz([0-9]+)\tint([0-9]+)\t//) { $peaks_count++; }
						}
						while($line=<IN>)
						{
							chomp($line);
							if ($line=~s/^([^\t]+)\t//)
							{
								my $scan=$1;
								if ($line=~s/\t([^\t]+)$//)
								{
									my $ok=$1;
									if ($ok>0)
									{
										for(my $i=0;$i<$peaks_count;$i++)
										{
											if ($line=~s/^([^\t]+)\t([^\t]+)\t//)
											{
												$heavy{qq!$scan#$i!}=$2;
												$scans{qq!$scan!}=1;
											}
										}
									}
								}
							}
						}
						close(IN);
						$count++;
						if (open(OUT,">$dir/$pep-both-z$z.txt"))
						{
							print OUT qq!scan!;
							for(my $i=0;$i<$peaks_count;$i++)
							{
								print OUT qq!\tlight$i\theavy$i!;
							}
							print OUT qq!\tlogproduct\tratio\n!;
							foreach my $scan (sort { $a <=> $b } keys %scans)
							{
								my $print=0;
								if ($light{qq!$scan#0!}<0.6*$light{qq!$scan#1!} and $heavy{qq!$scan#0!}<0.6*$heavy{qq!$scan#1!} and $light{qq!$scan#1!}>0 and $heavy{qq!$scan#1!}>0 and $light{qq!$scan#2!}>0 and $heavy{qq!$scan#2!}>0) { $print=1; }
								#for(my $i=0;$i<$peaks_count;$i++)
								#{
								#	if ($light{qq!$scan#$i!}>0 and $heavy{qq!$scan#$i!}>0) { $print=1; }
								#}
								if ($print==1)
								{
									print OUT qq!$scan!;
									for(my $i=0;$i<$peaks_count;$i++)
									{
										if ($i==0)
										{
											if ($light{qq!$scan#$i!}>0 or $heavy{qq!$scan#$i!}>0)
											{
												if ($light{qq!$scan#$i!}<=0) { $light{qq!$scan#$i!}=-1; }
												if ($heavy{qq!$scan#$i!}<=0) { $heavy{qq!$scan#$i!}=-1; }
												print OUT qq!\t$light{"$scan#$i"}\t$heavy{"$scan#$i"}!;
											}
											else
											{
												print OUT qq!\t-1\t-1!;
											}
										}
										else
										{
											if ($light{qq!$scan#$i!}>0 and $heavy{qq!$scan#$i!}>0)
											{
												print OUT qq!\t$light{"$scan#$i"}\t$heavy{"$scan#$i"}!;
											}
											else
											{
												print OUT qq!\t-1\t-1!;
											}
										}
									}
									my $product=-1; 
									my $ratio=-1;
									if ($light{qq!$scan#1!}>0 and $heavy{qq!$scan#1!}>0 and $light{qq!$scan#2!}>0 and $heavy{qq!$scan#2!}>0)
									{
										$product = log($light{qq!$scan#1!}) + log($heavy{qq!$scan#1!}) + log($light{qq!$scan#2!}) + log($heavy{qq!$scan#2!});
										$ratio = ($heavy{qq!$scan#1!} + $heavy{qq!$scan#2!}) / ($light{qq!$scan#1!} + $light{qq!$scan#2!});
									}
									print OUT qq!\t$product\t$ratio\n!;
								}
							}
							close(OUT);
						}
					}

				}
			}
		}
		print qq!$count\n!;
	}
}


