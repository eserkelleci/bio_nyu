#!/usr/local/bin/perl
#

sub numerically { $a <=> $b; }

$proton_mass=1.007276;
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

$ion_masses{"b"} = $proton_mass;
$ion_masses{"c"} = $atom_masses{"N"} + 3*$atom_masses{"H"} + $proton_mass;
$ion_masses{"y"} = $atom_masses{"O"} + 2*$atom_masses{"H"} + $proton_mass;;
$ion_masses{"z"} = 2*$atom_masses{"H"} + $atom_masses{"O"} - 2*$atom_masses{"H"} - $atom_masses{"N"} + $proton_mass;

$aa_masses_{'A'}=71.037110;
$aa_masses_{'B'}=114.042930;
$aa_masses_{'C'}=103.009190;
$aa_masses_{'D'}=115.026940;
$aa_masses_{'E'}=129.042590;
$aa_masses_{'F'}=147.068410;
$aa_masses_{'G'}=57.021460;
$aa_masses_{'H'}=137.058912;
$aa_masses_{'I'}=113.084060;
$aa_masses_{'J'}=0.0;
$aa_masses_{'K'}=128.094960;
$aa_masses_{'L'}=113.084060;
$aa_masses_{'M'}=131.040490;
$aa_masses_{'N'}=114.042930;
$aa_masses_{'O'}=0.0;
$aa_masses_{'P'}=97.052760;
$aa_masses_{'Q'}=128.058580;
$aa_masses_{'R'}=156.101110;
$aa_masses_{'S'}=87.032030;
$aa_masses_{'T'}=101.047680;
$aa_masses_{'U'}=150.953640;
$aa_masses_{'V'}=99.068410;
$aa_masses_{'W'}=186.079310;
$aa_masses_{'X'}=111.060000;
$aa_masses_{'Y'}=163.063330;
$aa_masses_{'Z'}=128.058580;

$aa_masses{'A'} = calc_aa_mass("C3H5ON");
$aa_masses{'B'} = calc_aa_mass("C4H6O2N2");	# Same as N
$aa_masses{'C'} = calc_aa_mass("C3H5ONS");
$aa_masses{'D'} = calc_aa_mass("C4H5O3N");
$aa_masses{'E'} = calc_aa_mass("C5H7O3N");
$aa_masses{'F'} = calc_aa_mass("C9H9ON");
$aa_masses{'G'} = calc_aa_mass("C2H3ON");
$aa_masses{'H'} = calc_aa_mass("C6H7ON3");
$aa_masses{'I'} = calc_aa_mass("C6H11ON");
$aa_masses{'J'} = 0.0;
$aa_masses{'K'} = calc_aa_mass("C6H12ON2");
$aa_masses{'L'} = calc_aa_mass("C6H11ON");
$aa_masses{'M'} = calc_aa_mass("C5H9ONS");
$aa_masses{'N'} = calc_aa_mass("C4H6O2N2");
$aa_masses{'O'} = calc_aa_mass("C4H6O2N2");	# Same as N
$aa_masses{'P'} = calc_aa_mass("C5H7ON");
$aa_masses{'Q'} = calc_aa_mass("C5H8O2N2");
$aa_masses{'R'} = calc_aa_mass("C6H12ON4");
$aa_masses{'S'} = calc_aa_mass("C3H5O2N");
$aa_masses{'T'} = calc_aa_mass("C4H7O2N");
$aa_masses{'U'} = 150.953640;	# Why?
$aa_masses{'V'} = calc_aa_mass("C5H9ON");
$aa_masses{'W'} = calc_aa_mass("C11H10ON2");
$aa_masses{'X'} = 111.060000;	# Why?
$aa_masses{'Y'} = calc_aa_mass("C9H9O2N");
$aa_masses{'Z'} = calc_aa_mass("C5H8O2N2");	# Same as Q

sub calc_aa_mass
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

sub Pepmz
{
	my $peptide = shift();
	my $charge = shift();
	my $phosphorylated = shift(); $phosphorylated=",$phosphorylated,";

	$mass = PepMass($peptide,$phosphorylated)/$charge + $proton_mass;

	return $mass;
}

sub PepMH 
{
	my $peptide = shift();
	my $phosphorylated = shift(); $phosphorylated=",$phosphorylated,";

	$mass = PepMass($peptide,$phosphorylated) + $proton_mass;

	return $mass;
}

sub PepMass 
{
	my $peptide = shift();
	my $phosphorylated = shift(); $phosphorylated=",$phosphorylated,";
	my $mass=0.0;
	my $err=0;

	$phospho_count=0;
	while ($phosphorylated=~s/,([0-9]+),/,/) 
	{
		$phospho_count++;
	}
	while ($peptide=~/\w/ and $err==0)
	{
		if ($peptide=~s/^([A-Z])//) { $mass+=$aa_masses{$1}; } else { $err=1; }
	}
	$mass+=$molecule_masses{"H2O"} + $phospho_count*$molecule_masses{"HPO3"};
	if ($err==0) { return $mass; } else { return -1; }
}


sub Fragments 
{
	my $peptide = shift();
	my $phosphorylated = shift(); $phosphorylated=",$phosphorylated,";
	my $ion_types = shift();
	my $err=0;
	my $mass=0.0;
	my $aa="";

	while($ion_types=~s/^([bcyz])//)
	{
		$ion_type=$1;
		$mass=$ion_masses{$ion_type};
		my $peptide_ = $peptide;
		if ($ion_type=~/[bc]/)
		{
			$this_frag_ST_phos=0;
			$index=0;
			while ($peptide_=~s/^([A-Z])//)
			{
				$aa=$1;
				$mass+=$aa_masses{$aa};
				if ($phosphorylated=~/,$index,/) 
				{
					$mass+=$molecule_masses{"HPO3"}; 
					if ($aa=~/^[ST]$/) { $this_frag_ST_phos=1; }
				}
				$index__=$index+1;
				if ($index__>1 and $index__<length($peptide))
				{
					@fragments=(@fragments,"$mass");
					#@fragments=(@fragments,"$mass (b$index__) $this_frag_ST_phos");
				}
				$index++;
			}
		}
		else
		{
			$this_frag_ST_phos=0;
			$index=length($peptide)-1;
			while ($peptide_=~s/([A-Z])$//)
			{
				$aa=$1;
				$mass+=$aa_masses{$aa};
				if ($phosphorylated=~/,$index,/)
				{
					$mass+=$molecule_masses{"HPO3"}; 
					if ($aa=~/^[ST]$/) { $this_frag_ST_phos=1; }
				}
				$index__=length($peptide)-$index;
				if ($index__>1 and $index__<length($peptide))
				{
					@fragments=(@fragments,"$mass");
					#@fragments=(@fragments,"$mass (y$index__) $this_frag_ST_phos");
				}
				$index--;
			}
		}
	}
	if ($err==0) { return 1; } else { return ""; }
}

1;