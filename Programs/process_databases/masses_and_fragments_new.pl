#!/usr/local/bin/perl
#
use strict;
sub numerically { $a <=> $b; }

my %atom_masses=();
my $proton_mass=1.007276;
$atom_masses{"H"}=1.007825035;
$atom_masses{"O"}=15.99491463;
$atom_masses{"N"}=14.003074;
$atom_masses{"C"}=12.0;
$atom_masses{"S"}=31.9720707;
$atom_masses{"P"}=30.973762;

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
	
sub calc_pep_mono_mass
{
	my $error=0;
	my $peptide = shift();
	my $modifications = shift();
	
	my %molecule_masses=();
	my %aa_masses=();
	my %modifications=();
	if($modifications!~/\,$/) { $modifications.=","; }
	while($modifications=~s/^([^\@]+)\@([^\,]+)\,//)
	{
		$modifications{$2}=$1;
	}

	$molecule_masses{"H2O"}=2*$atom_masses{"H"} + $atom_masses{"O"};
	$molecule_masses{"NH3"} = $atom_masses{"N"} + 3*$atom_masses{"H"};
	$molecule_masses{"HPO3"} = $atom_masses{"H"} + $atom_masses{"P"} + 3*$atom_masses{"O"};
	$molecule_masses{"H3PO4"} = 3*$atom_masses{"H"} + $atom_masses{"P"} + 4*$atom_masses{"O"};

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
	
	my $mass=0.0;
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
		my $index_=1;
		while ($peptide=~/\w/ and $error==0)
		{
			if ($peptide=~s/^([A-Z])//) 
			{
				my $aa=$1;
				$mass+=$aa_masses{$aa}; 
				if ($modifications{$aa}=~/\w/)
				{
					$mass+=$modifications{$aa};
				}
				if ($modifications{$index_}=~/\w/)
				{
					$mass+=$modifications{$index_};
				}
				$index_++;
			} else { $error=1; }
		}
		$mass+=$molecule_masses{"H2O"};
	}
	if ($error==0) { return $mass; } else { return -1; }
}

sub calc_pep_mono_mz
{
	my $peptide = shift();
	my $modifications = shift();
	my $charge = shift();

	my $proton_mass=1.007276;
	my $mz = calc_pep_mono_mass($peptide,$modifications)/$charge + $proton_mass;

	return $mz;
}

sub calc_pep_mono_MH 
{
	my $peptide = shift();
	my $modifications = shift();

	my $proton_mass=1.007276;
	my $mh = calc_pep_mono_mass($peptide,$modifications) + $proton_mass;

	return $mh;
}

sub calc_mz_of_new_charge_state 
{
	my $mz_old = shift();
	my $charge_old = shift();
	my $charge_new = shift();

	my $proton_mass=1.007276;
	my $mz_new = (  ($mz_old - $proton_mass) * $charge_old  ) / $charge_new + $proton_mass;

	return $mz_new;
}

sub calc_fragment_mzs
{
	my $err=0;
	my $peptide = shift();
	my $modifications = shift();
	my $ion_types = shift();
	my $fragments_ref = shift();
	
	if ($ion_types!~/\w/) { $ion_types="by"; }
	my %atom_masses=();
	my %molecule_masses=();
	my %aa_masses=();
	my %modifications=();
	if($modifications!~/\,$/) { $modifications.=","; }
	while($modifications=~s/^([^\@]+)\@([^\,]+)\,//)
	{
		$modifications{$2}=$1;
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
	
	my %ion_masses=();
	$ion_masses{"b"} = $proton_mass;
	$ion_masses{"c"} = $atom_masses{"N"} + 3*$atom_masses{"H"} + $proton_mass;
	$ion_masses{"y"} = $atom_masses{"O"} + 2*$atom_masses{"H"} + $proton_mass;;
	$ion_masses{"z"} = 2*$atom_masses{"H"} + $atom_masses{"O"} - 2*$atom_masses{"H"} - $atom_masses{"N"} + $proton_mass;

	while($ion_types=~s/^([bcyz])//)
	{
		my $ion_type=$1;
		my $mass=$ion_masses{$ion_type};
		my $peptide_ = $peptide;
		if ($ion_type=~/[bc]/)
		{
			my $index=0;
			while ($peptide_=~s/^([A-Z])//)
			{
				my $aa=$1;
				my $index_=$index+1;
				my $index__=$index+1;
				$mass+=$aa_masses{$aa};
				if ($modifications{$aa}=~/\w/)
				{
					$mass+=$modifications{$aa};
				}
				if ($modifications{$index_}=~/\w/)
				{
					$mass+=$modifications{$index_};
				}
				if ($index__>1 and $index__<length($peptide))
				{
					@$fragments_ref=(@$fragments_ref,"$mass b$index__");
				}
				$index++;
			}
		}
		else
		{
			my $index=length($peptide)-1;
			while ($peptide_=~s/([A-Z])$//)
			{
				my $aa=$1;
				my $index_=$index+1;
				my $index__=length($peptide)-$index;
				$mass+=$aa_masses{$aa};
				if ($modifications{$aa}=~/\w/)
				{
					$mass+=$modifications{$aa};
				}
				if ($modifications{$index_}=~/\w/)
				{
					$mass+=$modifications{$index_};
				}
				if ($index__>1 and $index__<length($peptide))
				{
					@$fragments_ref=(@$fragments_ref,"$mass y$index__");
				}
				$index--;
			}
		}
	}
	if ($err==0) { return 1; } else { return ""; }
}

1;