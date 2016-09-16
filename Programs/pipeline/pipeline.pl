#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program parses the XML file
#-------------------------------------------------------------------------#
use XML::Simple;
use Data::Dumper;
use strict;
use File::Copy;

my $error=0;
my $project_name="";
my $date="";
my $filename="";
my $local_dir="";
my $download_files=1;
my $line="";
my $filename_exp_local="";
my @base_file="";
my $method_file="";
my $result_folder="";
my $cluster_flag=0;
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

if ($ARGV[0]=~/\w/) { $filename="$ARGV[0]"; } else { $error=1; }
if ($ARGV[1]=~/\w/) { $date="$ARGV[1]";} else { $error=1; }
if ($ARGV[2]=~/\w/) { $project_name="$ARGV[2]";} else { $error=1; }
if ($ARGV[3]=~/\w/) { $result_folder="$ARGV[3]";} else { $error=1; }

$local_dir = $result_folder."/".$project_name."-".$date; 
mkdir($local_dir);
my $local_dir_=$local_dir; $local_dir_=~s/\//\\/g;

my $data_dir=$result_folder;  
$data_dir=~s/$SETTINGS{'RESULT'}/$SETTINGS{'DATA'}/; 
$data_dir=~s/\//\\/g; 

if ($error==0) { if (open(IN,"$filename")) { close(IN); } else { print qq!$filename not found\n!; $error=1; } }
if ($error==0)
{
	my %programs=();
	if (open(IN,"../programs.txt"))
	{
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
			{
				$programs{"$1#$2"}=$3; 
			}
		}
		close(IN);
	}
	my $analysis = XMLin($filename, forcearray=>[ 'step' ]);
	copy("$filename", "$local_dir");
	my $filename_exp = $analysis->{experiment}->{file};
	my $result_dir = $analysis->{result}->{dir};
	my $step_count=0;
	my $step_count_=0;
	foreach my $step (@{$analysis->{step}})
	{
		if (open(IN,"stop")) 
		{ 
			close(IN); 
		}
		else
		{
			$step_count_=$step_count+1;
			my $step_done=0;
			$filename_exp_local=$filename_exp;
			if ($filename_exp_local=~/^(.*)\/([^\/]+)$/)
			{
				$filename_exp_local = $2;
			}
			my $filename_exp_local_=$filename_exp_local;
			if ($step_count>0) 
			{ 
				$filename_exp_local_=~s/\.xml$/_step$step_count.xml/; 
				my $filename_exp_local__=$filename_exp_local;
				$filename_exp_local__=~s/\.xml$/_step$step_count_.xml/; 
				if (open(IN,"$local_dir/$filename_exp_local__"))
				{
					$step_done=1;
					close(IN);
				}
			}
			else
			{
				if ($download_files==1)
				{
					copy("$filename_exp", "$local_dir");
					my $experiment = XMLin("$local_dir/$filename_exp_local", forcearray=>[ 'group', 'sample', 'file' ]);
					my $filename_="";
					foreach my $group (@{$experiment->{group}})
					{
						my $group_id = $group->{id_};
						foreach my $sample (@{$group->{sample}})
						{
							my $sample_id = $sample->{id_};
							foreach my $file (@{$sample->{file}})
							{
								$filename_=$file->{path};
								copy("$filename_","$local_dir");
							}
						}
					}
					my $experiment = XMLin("$local_dir/$filename_exp_local", forcearray=>[ 'group', 'sample', 'file' ]);
					my $filename_="";
					foreach my $group (@{$experiment->{group}})
					{
						my $group_id = $group->{id_};
						foreach my $sample (@{$group->{sample}})
						{
							my $sample_id = $sample->{id_};
							foreach my $file (@{$sample->{file}})
							{
								$filename_=$file->{path};
								my $flag=0;
								my $mgffile="";
								if ($filename_=~/^(.*)\/([^\/]+)$/)
								{
									$mgffile=$2; 
									if($mgffile=~/^(.*).mgf$/)
									{
										open(IN,"$local_dir/$mgffile") || die "could not open $local_dir/$mgffile file"; 
										my $line1="";
										while($line1=<IN>)
										{
											chomp($line1); 
											if($line1=~/TITLE=.*Locus.*/) 
											{
												$flag=1;
											} 
											elsif($line1=~/TITLE=.*Spectrum.*/) 
											{
												$flag=2;
											}
										}
										close(IN);
									}
								}
								if($flag==1)
								{
									$flag=0;
									my $new_filename=$mgffile; 
									$new_filename=~s/\.mgf/\.old\.mgf/;
									rename("$local_dir/$mgffile","$local_dir/$new_filename"); 
									system(qq!D://Programs//process_data//transform_cptacmgf.pl "$local_dir/$new_filename" "$local_dir"!);
								}
								elsif($flag==2)
								{
									$flag=0;
									my $new_filename=$mgffile; 
									$new_filename=~s/\.mgf/\.old\.mgf/;
									rename("$local_dir/$mgffile","$local_dir/$new_filename"); 
									system(qq!D://Programs//process_data//transform_lobelmgf.pl "$local_dir/$new_filename" "$local_dir"!);
								}
							}
						}
					}
				} else { $step_done=1; }
			}
			if ($step_done==0)
			{
				my $type = $step->{type};
				my $program = $step->{program};
				my $method = $step->{method};
				my $method_=" ";
				if ($method=~/\w/)
				{
						if ($method=~/^(.*)\/([^\/]+)$/)
						{
							$method_="$local_dir/$2";
							copy("$SETTINGS{'TASKS'}/methods/$1/$2","$local_dir");
						}
						if ($method=~/^(.*)\/([^\/]+)$/)
						{
							$method_file=$2;
						}
						else
						{
							$method_=$method;
						}
				}
				if($program eq "ProteoWizard_exp.pl")
				{
					my $method__=$method_;
					$method__=~s/\"/#/g;
					 print qq!---$step_count_. $programs{"$type#$program"}$program "$local_dir/$filename_exp_local_" "$method__"\n!;
					 system(qq!$programs{"$type#$program"}$program "$local_dir/$filename_exp_local_" "$method__"!);
				}
				else
				{
					if($program eq "xtandem_cluster.pl")
					{
						$cluster_flag=1;
					}
					 print qq!---$step_count_. $programs{"$type#$program"}$program "$local_dir/$filename_exp_local_" \'$method_\'\n!;
					 system(qq!$programs{"$type#$program"}$program "$local_dir/$filename_exp_local_" \"$method_\"!);
				}
			}
			else
			{
				print qq!---Skipped: $step_count_. $step->{type}, $step->{program}, $step->{method}\n!;
			}
		}
		$step_count++;
	}
		
	open(IN,qq!$local_dir/$filename_exp_local!);
	my $iter=0;
	while($line=<IN>)
	{
		if($line=~/\<file path=\"(.*)\/([^\/]+)\"\/>/)
		{
			$base_file[$iter]=$2;
			$iter++;
		}
	}
	close(IN);
	for(my $i=0;$i<$iter;$i++)
	{
		if($base_file[$i]=~/(.*)\.mgf$/ and $cluster_flag==1)
		{
		}
		else
		{
			system(qq!del "$local_dir_\\$base_file[$i]"!);
			if($base_file[$i]=~/(.*)\.mgf$/) { system(qq!del "$local_dir_\\$1.old.mgf"!); }
		}
	}
	mkdir("$local_dir/methods"); 	
	system(qq!move "$local_dir_\\*-analysis.xml" "$local_dir_\\methods"!);
	system(qq!move "$local_dir_\\$method_file" "$local_dir_\\methods"!);
	system(qq!move "$local_dir_\\*-experiment.xml" "$local_dir_\\methods"!);
	system(qq!move "$local_dir_\\*-experiment_*.xml" "$local_dir_\\methods"!);
	
	mkdir("$local_dir/plots");
	mkdir("$local_dir/plots/data");
	mkdir("$local_dir/plots/data/base_peak");	
	system(qq!move "$local_dir_\\*MS1.MGF" "$local_dir_\\plots\\data\\base_peak"!);
	system(qq!move "$local_dir_\\*MS1.MGF.basepeak.*" "$local_dir_\\plots\\data\\base_peak"!);
	
	mkdir("$local_dir/plots/id");
	mkdir("$local_dir/plots/id/base_peak"); 	
	system(qq!move "$local_dir_\\*.basepeak.*" "$local_dir_\\plots\\id\\base_peak"!);	
	
	if(glob("$local_dir/*.mgf") or glob("$local_dir/*.MGF"))
	{
		system(qq!move "$local_dir_\\*.mgf" "$data_dir"!);
		system(qq!move "$local_dir_\\*.MGF" "$data_dir"!);
	}
	
}

sub GetDateTime
{
	my $sec="";
	my $min="";
	my $hour="";
	my $mday="";
	my $mon="";
	my $year="";

	($sec,$min,$hour,$mday,$mon,$year) = localtime();

	if ($sec<10) { $sec="0$sec"; }
	if ($min<10) { $min="0$min"; }
	if ($hour<10) { $hour="0$hour"; }
	if ($mday<10) { $mday="0$mday"; }
	$mon++;
	if ($mon<10) { $mon="0$mon"; }
	$year+=1900;
	my $date="$year-$mon-$mday-$hour-$min-$sec";
	
	return $date;
}