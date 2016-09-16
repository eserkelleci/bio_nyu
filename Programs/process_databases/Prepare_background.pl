#!/usr/local/bin/perl
#

require "./masses_and_fragments.pl";

$error=0;
if ($ARGV[0]=~/\w/) { $DBfilename=$ARGV[0];} else { $DBfilename="scd.fasta"; }
if ($ARGV[1]=~/\w/) { $parent_mass=$ARGV[1];} else { $parent_mass=2000; }
if ($ARGV[2]=~/\w/) { $parent_mass_error=$ARGV[2];} else { $parent_mass_error=0.1; }
if ($ARGV[3]=~/\w/) { $number_of_fragments=$ARGV[3];} else { $number_of_fragments="3,5,7,9,11,15"; }
if ($ARGV[4]=~/\w/) { $total_number_of_fragments=$ARGV[4];} else { $total_number_of_fragments=0; }
if ($ARGV[5]=~/\w/) { $charge=$ARGV[5];} else { $charge=2; }
if ($ARGV[6]=~/\w/) { $ion_types=$ARGV[6];} else { $ion_types="by"; }
if ($ARGV[7]=~/\w/) { $srand=$ARGV[7];} else { $srand=13579; }
if ($ARGV[8]=~/\w/) { $incompletes=$ARGV[8];} else { $incompletes=0; }

$total_pep_count=0;
$total_pep_count_max=1000000;
$iterations=1;
system(qq!del "$DBfilename.$parent_mass.$parent_mass_error.*.mgf"!);
$number_of_fragments_=$number_of_fragments;
@number_of_fragments=();
$max_number_of_fragments=0;
while($number_of_fragments_=~s/^\s*([0-9]+)\s*,?\s*//) 
{ 
	@number_of_fragments=(@number_of_fragments,$1); 
	if ($max_number_of_fragments<$1) { $max_number_of_fragments=$1; }
}
srand($srand);
my %PEP=();
$files_count=0;
$peptides_count=0;
$proteins_count=0;
if (open (IN,"$DBfilename"))
{
	$name="";
	$sequence="";
	while ($line=<IN> and $total_pep_count<$total_pep_count_max)
	{
		chomp($line);
		if ($line=~/^>(\S+)\s?(.*)$/)
		{
			$name_=$1;
			if ($name=~/\w/ and $sequence=~/\w/)
			{
				$proteins_count++;
				#print "$proteins_count. $name\n";
				%PEP=();
				DigestTrypsin($name,$sequence,$incompletes);
				write_mgf($iterations);
			}
			$name=$name_;
			$description=$description_;
			$sequence="";
		}
		else
		{
			$sequence.="$line";
		}
	}	
	if ($name=~/\w/ and $sequence=~/\w/ and $total_pep_count<$total_pep_count_max)
	{

		$proteins_count++;
		#print "$proteins_count. $name\n";
		%PEP=();
		DigestTrypsin($name,$sequence,$incompletes);
		write_mgf($iterations);
	}
	close(IN);
}

sub DigestTrypsin
{
	my $name = shift();
	my $seq = shift();
	my $incompletes = shift();

	my $temp=$seq;
	my @pep=();
	my @start=();
	my @end=();
	my $aa="";
	my $aa_="";
	my $i=0;

	for($i=0;$i<=$incompletes;$i++)
	{
		$start[$i]=0;
		$end[$i]=-1;
		#$pep[$i]="[";
	}
	my $aa_count=0;
	while ($temp=~s/^\s*([A-Z])//)
	{
		$aa=$1;
		if ( ($aa_=~/R/ or $aa_=~/K/) and $aa!~/P/)
		{
			for($i=0;$i<=$incompletes;$i++)
			{
				$PEP{"$pep[$i]"}=1;
				$pep[$i]=$pep[$i+1];
				$start[$i]=$start[$i+1];
				$end[$i]=$end[$i+1];
			}
			$start[$incompletes]=$aa_count;
			$end[$incompletes]=$aa_count-1;
		}
		for($i=0;$i<=$incompletes;$i++)
		{
			$pep[$i].=$aa;
			$end[$i]++;
		}
		$aa_=$aa;
		$aa_count++;
	}
	for($i=0;$i<=$incompletes;$i++)
	{
		$PEP{"$pep[$i]"}=1;
	}
}


sub write_mgf
{
	my $iterations = shift();
	my $done_this_proteins=0;
	my $i=0;

	foreach $peptide (keys %PEP)
	{
		if ($done_this_proteins==0)
		{
				$MH=PepMH($peptide);
				#print "*$peptide $MH,$parent_mass,$parent_mass_error\n";
				if (abs($MH-$parent_mass)<=$parent_mass_error)
				{
					$done_this_proteins=1;
					#print "$peptide $MH\n";
					@fragments=();
					Fragments($peptide,"",$ion_types);
					$fragments=@fragments;
					$mz=Pepmz($peptide,$charge);
					foreach $number_of_fragments_ (@number_of_fragments)
					{
						#print "$peptides_count. #$number_of_fragments_#\n";
						if ($number_of_fragments_=~/([0-9]+)/)
						{
							if ($max_number_of_fragments>$fragments)
							{
								print "Error: $peptide $number_of_fragments_ ($max_number_of_fragments>$fragments)\n";
							}
							else
							{
								for($iter=0;$iter<$iterations;$iter++)
								{
									@selected=();
									#print "$peptide $number_of_fragments_ ($fragments)\n";
									$found=0;
									while($found<$number_of_fragments_)
									{
										$i=rand()*$fragments;
										$i=~s/\..*$//;
										if ($selected[$i]!~/\w/)
										{
											$selected[$i]=1;
											$found++;
										}
									}
									@fragments_=();
									$found=0;
									for($i=0;$i<$fragments;$i++)
									{
										if($selected[$i]=~/\w/)
										{
											$fragments_[$found++]=$fragments[$i]; 
										}
									}
									if ($total_number_of_fragments==0) { $total_number_of_fragments_=$number_of_fragments_; } else { $total_number_of_fragments_=total_number_of_fragments; }
									if (open(outfile,"$DBfilename.$parent_mass.$parent_mass_error.$number_of_fragments_.$total_number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf"))
									{
										close(outfile);
									}
									else
									{
										if (open(outfile,">$DBfilename.$parent_mass.$parent_mass_error.$number_of_fragments_.$total_number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf"))
										{
											print outfile qq!BEGIN IONS\n!;
											print outfile qq!TITLE=$peptide, MH=$MH, z=$charge, mz=$mz $ion_types, $number_of_fragments_ ($fragments)\n!;
											print outfile qq!PEPMASS=$mz\n!;
											print outfile qq!CHARGE=$charge+\n!;
											foreach $fragment (sort numerically @fragments_)
											{
												print outfile "$fragment 100\n";
											}
											print outfile qq!END IONS\n\n!;
											$files_count++;
											close(outfile);
											if ($max_number_of_fragments==$number_of_fragments_ and $iter==0) { $total_pep_count++; }
										}
										else
										{
											print "Error opening $DBfilename.$parent_mass.$parent_mass_error.$number_of_fragments_.$total_number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf\n";
										}
									}
								}
							}
						}
						else
						{
							print "Error\n";
						}
					}
				}
		}
	}
}

$peptides_count=$files_count/($iterations*@number_of_fragments);
print "$DBfilename, Mp=$parent_mass, Mp-error=$parent_mass_error, z=$charge, $ion_types, $srand $peptides_count ($total_pep_count, $total_pep_count_max)\n";