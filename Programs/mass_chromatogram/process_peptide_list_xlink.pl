#!/usr/local/bin/perl
#

use strict;

my $error=0;
my $filename="";
my $filename_="";
my $mass_error=0;
my $fixed_modifications="";
my $modifications="";
my $modifications_="";
my @mod_mod=();
my @mod_aa=();
my $mod_count=0;
my $this_mod_count=0;
my $this_mod_count_=0;
my $charge_min=0;
my $charge_max=0;
my $split=1;
my $residues_to_remove=0;
my $peptides_count=0;
my $peptides_count_=0;
my $pep="";
my $i=0;
my $j=0;
my $k=1;
my $l=0;
my $l_=0;
my $m=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="crosslinks.txt"; }
if ($ARGV[1]=~/\w/) { $mass_error=$ARGV[1];} else { $mass_error=20; }
if ($ARGV[2]=~/\w/) { $fixed_modifications=$ARGV[2];} else { $fixed_modifications="57.021464\@C"; }
if ($ARGV[3]=~/\w/) { $charge_min=$ARGV[3];} else { $charge_min=2; }
if ($ARGV[4]=~/\w/) { $charge_max=$ARGV[4];} else { $charge_max=6; }
if ($ARGV[5]=~/\w/) { $split=$ARGV[5];} else { $split=1; }

$filename_=$filename;
$filename_=~s/\.txt//;
if($fixed_modifications!~/\,$/) { $fixed_modifications.=","; }
my $header="";
if ($split<1) { $split=1; }
my $line_count=0;
my $split_count=0;
my $line="";
if (open (IN,"$filename"))
{		
	$header=<IN>;
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([0-9]+)\t([0-9]+)\t([0-9]+)\t([A-Z\t]+)$/)
		{
			$line_count++;
		}
	}
	close(IN);
	$split_count=int($line_count/$split)+1;
}
if (open (IN,"$filename"))
{
	my $split_=0;
	if ($split<=1)
	{
		open(OUT,">$filename_.processed.txt");
	}
	else
	{
		open(OUT,">$filename_.$split_.$split.processed.txt");
	}
	my $line_count_=0;
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^([0-9]+)\t([0-9]+)\t([0-9]+)\t([A-Z\t]+)$/)
		{
			my $xlink_count=$2;
			my $component_count=$3;
			my $peptides=$4;
			my $peptides_=$peptides;
			$peptides_=~s/\t/_/g;
			
			if ($split_count*($split_+1)<=$peptides_count)
			{
				close(OUT);
				$split_++;
				open(OUT,">$filename_.$split_.$split.processed.txt");
			}
			$this_mod_count = ($peptides=~tr/M/M/);
			$this_mod_count_ = ($peptides=~tr/N/N/);
			my $temp="$peptides\t";
			my $m=0;
			while($temp=~s/^([A-Z]+)\t//)
			{
				my $pep=$1;
				$m+=calc_pep_mono_mass($pep,$fixed_modifications,"");
			}
			$m-=$xlink_count*2*1.007825035;
			for($k=$charge_min;$k<=$charge_max;$k++)
			{
				for($l=0;$l<=$this_mod_count;$l++)
				{
					for($l_=0;$l_<=$this_mod_count_;$l_++)
					{
						my $m_=$m+$l*15.99491463+$l_*0.984016;
						my $mz=($m_+$k*1.007276-1.007276)/$k;
						for(my $n=0;$n<=3;$n++)
						{
							my $mz_=$mz*(1-$mass_error/1e+6);
							my $mz__=$mz*(1+$mass_error/1e+6);
							my $temp="";
							if ($xlink_count>0) { $temp.="YY$xlink_count, "; } 
							if ($l>0) { $temp.="O$l\@M, "; } 
							if ($l_>0) { $temp.="0.984-$l_\@N, "; } 
							print OUT qq!$peptides_\t$temp\t$k\t$mz\t500\t$n\tP\t0\t1000000\t$mz_\t$mz__\n!;
							$mz+=1.007276/$k;
						}
						$peptides_count_++;
					}
				}
			}
			$peptides_count++;
		}
	}	
	close(OUT);
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
	my $fixed_modifications = shift();
	my $modifications = shift();

	my $proton_mass=1.007276;
	my $mass = calc_pep_mono_mass($peptide,$fixed_modifications,$modifications)/$charge + $proton_mass;

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


