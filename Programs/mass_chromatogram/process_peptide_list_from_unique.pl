#!/usr/local/bin/perl
#

use strict;

my $error=0;
my $filename="";
my $filename_="";
my $mass_error=0;
my $charge_min=0;
my $charge_max=0;
my $peptides_count=0;
my $line="";
my %done=();
my $i=0;
my $j=0;
my $k=1;
my $l=0;
my $m=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="unique.txt"; }
if ($ARGV[1]=~/\w/) { $mass_error=$ARGV[1];} else { $mass_error=20; }
if ($ARGV[2]=~/\w/) { $charge_min=$ARGV[2];} else { $charge_min=1; }
if ($ARGV[3]=~/\w/) { $charge_max=$ARGV[3];} else { $charge_max=4; }

$filename_=$filename;
$filename_=~s/\.txt//;

if (open (IN,"$filename"))
{
	if (open(OUT,">$filename_.processed.txt"))
	{
		$line=<IN>;
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$/)
			{
				my $pep=$2;
				my $number=$4;
				my $modscans=$7;
				if ($number<=1)
				{
					while($modscans=~s/^([^\t]+)//)
					{
						my $modscan=$1;
						$modscan=~s/^\"//;
						$modscan=~s/\"$//;
						my $mod_mass=0;
						my $mod="";
						$modscans=~s/^\s*\t\s*//;
						if ($modscan=~/^([^\,]+)\,/)
						{
							my $mod_=$1;
							$mod_=~s/^\s*Unmodified\s*//;
							while($mod_=~s/^\s*[A-Z]+\s+(\[[0-9]+\])\s+([0-9\.\-\+edED]+)\s*//)
							{
								$mod_mass+=$2;
								$mod.="$2\@$1,";
							}
						}
						my $scan_min=0;
						my $scan_max=1000000;
						my $scan=500;
						if ($modscan=~/scan\s+([0-9]+)/)
						{
							$scan=$1;
							$scan_min=$scan-4000;
							$scan_max=$scan+4000;
						}
						if ($done{"$pep#$mod_mass"}!~/\w/)
						{
							$done{"$pep#$mod_mass"}=1;
							for($k=$charge_min;$k<=$charge_max;$k++)
							{
								my $mz=calc_pep_mono_mz($pep,$k,"","")+($mod_mass-1.007276)/$k;
								for($m=0;$m<=3;$m++)
								{
									my $mz_=$mz*(1-$mass_error/1e+6);
									my $mz__=$mz*(1+$mass_error/1e+6);
									print OUT qq!$pep\t$mod_mass\t$k\t$mz\t$scan\t$m\tP\t$scan_min\t$scan_max\t$mz_\t$mz__\n!;
									$mz+=1.007276/$k;
								}
							}
							$peptides_count++;
						}
					}
				}
			}
		}
		close(OUT);
	}	
	close(IN);
}

#print qq!$peptides_count, $peptides_count_!;

sub calc_pep_mono_mass
{
	my $peptide = shift();
	my $fixed_modifications = shift();
	my $modifications = shift();
	my $mass=0.0;
	my $err=0;
	my %atom_masses=();
	my %molecule_masses=();
	my %aa_masses=();
	my %fixed_modifications=();
	if($fixed_modifications!~/\,$/) { $fixed_modifications.=","; }
	while($fixed_modifications=~s/^([^\@]+)\@([^\,]+)\,//)
	{
		$fixed_modifications{$2}=$1;
	}

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
			if ($peptide=~s/^([A-Z])//) 
			{
				my $aa=$1;
				$mass+=$aa_masses{$aa}; 
				if ($fixed_modifications{$aa}=~/\w/)
				{
					if ($fixed_modifications{$aa}=~/^[A-Z]/)
					{
						$mass+=calc_aa_mono_mass($fixed_modifications{$aa});
					}
					else
					{
						$mass+=$fixed_modifications{$aa};				
					}
				}
			} else { $err=1; }
		}
		$mass+=$molecule_masses{"H2O"};
		if ($modifications=~/\w/)
		{
			if ($modifications=~/^[A-Z]/)
			{
				$mass+=calc_aa_mono_mass($modifications);
			}
			else
			{
				$mass+=$modifications;				
			}
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

