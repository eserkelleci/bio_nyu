#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program reads an MGF file, removes the charge reduced species, and then saves it.
#
#
#   Outline (pseudocode):
#
#	if the MGF file can be opened
#	{
#		while there are sill MS/MS spectra left to read
#		{
#			read next MS/MS spectrum
#			removes peaks that correspond to charge reduced species
#			write the MS/MS spectrum
#		}
#	}
#
#-------------------------------------------------------------------------#

use strict;

my $error=0;
my $MGFFileName="";
if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; } 
my $tolerance=0.8;
my $tolerance_isolation=2;

my $count_spectra=0;
my @count_charges=();
my $i=0;

if ($error==0)
{
	if(open (IN, "$MGFFileName"))
	{
		if(open (OUT,">$MGFFileName-altered.mgf"))
		{
			my $pepmass=0;
			my $title="";
			my $charge="";
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
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
				{
					$pepmass=$1;
				}
				if ($line=~/^CHARGE=([0-9\.\-\+]+)\s*$/)
				{
					$charge=$1;
				}
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
				{
					$started_reading_fragments=1;
					$mz[$points]=$1;
					$intensity[$points]=$2;
					
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
						#----------------------------------------------------------#
						#   Code to find charge and remove charge reduced species
						#----------------------------------------------------------#
						my $parent_mz=$pepmass;
						my $done=0;
						my $parent_ch=0;
						my $found_parent_ch=0;
						for($parent_ch=1;$parent_ch<=4 and $done==0;$parent_ch++)
						{
							my $reduced_mz = $parent_mz * $parent_ch / 1;
							if ($reduced_mz>=100 and $reduced_mz<=2000-100)
							{
								my $max_height=0;
								my $max_height_above=0;
								for(my $i=0;$i<$points;$i++)
								{
									if ($max_height<$intensity[$i]) { $max_height=$intensity[$i]; }
									if ($reduced_mz+$tolerance_isolation<$mz[$i]) 
									{ 
										if ($max_height_above<$intensity[$i]) { $max_height_above=$intensity[$i]; }
									}
								}
								if ($max_height_above/$max_height<0.05)
								{
									$done=1;
									$found_parent_ch=$parent_ch;
								}
								else
								{
									# Reduced 1+ within range, but there are large peaks above
								}
							}
							else
							{
								# Reduced 1+ outside range
								my $found_all_reduced=1;
									for(my $reduced_ch=$parent_ch-1;$reduced_ch>=2;$reduced_ch--)
									{
										my $max_height=0;										
										my $reduced_height=0;									
										my $reduced_mz = $parent_mz * $parent_ch / $reduced_ch;
										if ($reduced_mz>=100 and $reduced_mz<=2000)
										{
											for(my $i=0;$i<$points;$i++)
											{
												if ($max_height<$intensity[$i]) { $max_height=$intensity[$i]; };
												if (abs($mz[$i]-$reduced_mz)<$tolerance)
												{
													if ($reduced_height<$intensity[$i]) { $reduced_height=$intensity[$i]; };
												}
											}
										}
										if ($reduced_height<$max_height*0.3) { $found_all_reduced=0; }
									}
								if ($found_all_reduced==1)
								{
									$done=1;
									$found_parent_ch=$parent_ch;
								}
							}	
						}
						if ($done==1)
						{
							print "$title, $pepmass, $charge -> $found_parent_ch\+\n";
							$count_charges[$found_parent_ch]++;
							if ($found_parent_ch>1)
							{
								$header=~s/^CHARGE=.*$/CHARGE=$found_parent_ch\+/m;
								print OUT $header;
								for(my $i=0;$i<$points;$i++)
								{
									my $remove=0;
									for(my $reduced_ch=$found_parent_ch;$reduced_ch>=1;$reduced_ch--)
									{									
										my $reduced_mz = $parent_mz * $found_parent_ch / $reduced_ch;
										if (abs($mz[$i]-$reduced_mz)<$tolerance_isolation)
										{
											$remove=1;
										}
									}
									if ($remove==0)
									{
										print OUT "$mz[$i] $intensity[$i]\n";
									}
								}
								print OUT $footer;
							}
						}
						else
						{
							# no charge is found
							print "$title, $pepmass, $charge -> ?\n";
							$count_charges[0]++;
							for($found_parent_ch=3;$found_parent_ch<=4;$found_parent_ch++)
							{
								$header=~s/^CHARGE=.*$/CHARGE=$found_parent_ch\+/m;
								print OUT $header;
								for(my $i=0;$i<$points;$i++)
								{
									my $remove=0;
									for(my $reduced_ch=$found_parent_ch;$reduced_ch>=1;$reduced_ch--)
									{									
										my $reduced_mz = $parent_mz * $found_parent_ch / $reduced_ch;
										if (abs($mz[$i]-$reduced_mz)<$tolerance_isolation)
										{
											$remove=1;
										}
									}
									if ($remove==0)
									{
										print OUT "$mz[$i] $intensity[$i]\n";
									}
								}
								print OUT $footer;
							}
						}

						#----------------------------------------#
						
						$pepmass="";
						$title="";
						$charge="";
						@mz=();
						@intensity=();
						$header="";
						$footer="";
						$started_reading_fragments=0;
						$done_reading_fragments=0;
						$points=0;
						$count_spectra++;
					}
				}
			}
			close(OUT);
		}
		close(IN);
	} 
	else
	{
		print "Could not open \"$MGFFileName\".\n";
		$error=1;
	}
}
else
{
	print "Name of MGF file is missing\n";
}

if ($error==0)
{
	print "$count_spectra spectra found in \"$MGFFileName\".\n";
	for($i=0;$i<=4;$i++)
	{
		if ($count_charges[$i]!~/\w/) { $count_charges[$i]=0; }
		print "$i\+: $count_charges[$i] spectra\n";
	}
}