#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $dir="";
my $expect_threshold="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $expect_threshold=$ARGV[1];} else { $expect_threshold=0.001; }

if ($error==0)
{	
	$dir=~s/\\/\//g;
	my $dir_=$dir;
	$dir_=~s/\//\\/g;
	open (OUT,qq!>$dir.mutations.$expect_threshold.txt!) || die "Could not open output\n";
	my $line="";
	my %peptides=();
	
	my %mutations=();
	my $count_subunits=0;
	if (open(IN,"subunits.txt"))
	{
		my @name=();
		my @mass=();
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t+([^\t]+)\t*([^\t]*)$/)
			{
				$name[$count_subunits]=$1;
				$mass[$count_subunits]=$2+0.5;
				$mass[$count_subunits]=~s/\..*$//;
				if ($mass[$count_subunits]>0)
				{
					if ($line!~/^END/) { $count_subunits++; }
				}
			}
		}
		close(IN);
		for(my $i=0;$i<$count_subunits;$i++)
		{
			for(my $j=0;$j<$count_subunits;$j++)
			{
				if ($i!=$j)
				{
					my $mass_diff=$mass[$j]-$mass[$i];
					if ($mass_diff>=0) { $mass_diff+=0.5; } else { $mass_diff-=0.5; }
					$mass_diff=~s/\..*$//;
					$mutations{"$name[$i]#$mass_diff"}="$name[$j]";
				}
			}
		}
	}

	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.xml$/i)
			{
				open (IN,"$dir/$filename") || die "Could not open $dir/$filename\n";
				my $reversed=1;
				my $pep="";
				my $start="";
				my $expect="";
				my $mutations="";
				while ($line=<IN>)
				{
					if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
					{
						my $protein_name=$1;
						if ($protein_name!~/\:reversed$/) { $reversed=0; }
					}
					if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*start="([0-9]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
					{
						my $start=$2;
						my $expect=$3;
						my $pep=$6;
						#if ($reversed==0)
						{
							$pep=~tr/L/I/;
							$mutations="";
							my $domain_done=0;
							while ($domain_done==0)
							{
								$line=<IN>;
								chomp($line);
								if ($line=~/^\<\/domain\>/)
								{
									$domain_done=1;
								}
								else
								{
									if ($line=~/^\<aa\s+type="([A-Z])"\s+at="([0-9]+)"\s+modified="([0-9\.\-]+)"\s+p?m?=?"?([A-Z]?)"?\s*\/\>/)
									{
										my $mod_aa=$1;
										my $mod_pos=$2;
										my $mod_mass=$3;
										my $mod_pm=$4;
										if ($mod_pm=~/\w/)
										{
											my $temp_i=$mod_pos-$start+1;
											$mutations.=qq!$mod_aa$temp_i->$mod_pm#!;
										}
										else
										{
											my $mod_mass_=$mod_mass;
											if ($mod_mass_>=0) { $mod_mass_+=0.5; } else { $mod_mass_-=0.5; }
											$mod_mass_=~s/\..*$//;
											if (!($mod_aa=~/^S$/ and $mod_mass_==80) and 
												!($mod_aa=~/^T$/ and $mod_mass_==80) and 
												!($mod_aa=~/^Y$/ and $mod_mass_==80) and 
												!($mod_aa=~/^C$/) and $mod_mass_==57 and 
												!($mod_aa=~/^K$/ and $mod_mass_==42) and 
												!($mod_pos==$start and $mod_mass_==-18) and
												!($mod_pos==$start and $mod_mass_==-17) and 
												!($mod_pos==$start and $mod_mass_==42) and 
												!($mod_aa=~/^M$/ and $mod_mass_==16))
											{
												if ($mutations{"$mod_aa#$mod_mass_"}=~/\w/)
												{
													my $temp_i=$mod_pos-$start+1;
													my $mut=$mod_pm;
													if ($mut!~/\w/)
													{
														$mut=$mutations{"$mod_aa#$mod_mass_"};
													}
													$mutations.=qq!$mod_aa$temp_i->$mut#!;
												}
												else { print qq!Error: no modification or mutation found: $mod_aa $mod_pos $mod_mass\n!; }
											}
										}
									}
									else { print qq!Error parsing: $line\n!; }
								}
							}
							if ($peptides{"$pep#$mutations"}<$expect or $peptides{"$pep#$mutations"}!~/\w/) { $peptides{"$pep#$mutations"}=$expect; }
						}
					}
				}			
			}
		}
	}
	close(IN);
	foreach my $pepmut (sort keys %peptides)
	{
		if ($pepmut=~/^([^#]+)#(.*)$/)
		{
			my $pep=$1;
			my $mut=$2;
			if ($mut=~/\w/ and $peptides{"$pepmut"}<=$expect_threshold)
			{
				my $pep_=$pep;
				my $pep__="";
				my $temp=$mut;
				while ($temp=~s/^([^#]+)#//)
				{
					my $mut_=$1;
					if ($mut_=~s/^([A-Z])([0-9]+)\-\>([A-Z])$//)
					{
						my $aa_ori=$1;
						my $aa_pos=$2;
						my $aa_new=$3;
						$pep__ = substr $pep_,0,$aa_pos-1;
						$pep__ .= $aa_new;
						$pep__ .= substr $pep_,$aa_pos,length($pep_)-$aa_pos;
					}
					else { print qq!Error parsing mutation: $mut_\n!; }
					$pep_=$pep__;
				}
				print OUT qq!$pep\t$peptides{"$pepmut"}\t$mut\t$pep_\n!;
			}
		}
	}
	close(OUT);
}