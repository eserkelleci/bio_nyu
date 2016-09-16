#!/usr/local/bin/perl
use XML::Simple;
use Data::Dumper;
use strict;

my $error=0;
my $filename_exp="";
my $method="";
my $del="";
my $line="";
my @method_=("HCD","ETD","CID");
my $filename_="";
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
my %programs=(); if (open(IN,"../programs.txt")) { while($line=<IN>) { if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) { $programs{"$1#$2"}=$3; } } close(IN); }

if ($ARGV[0]=~/\w/) { $filename_exp="$ARGV[0]";} else { $error=0; }
if ($ARGV[1]=~/\w/) { $method="$ARGV[1]";} else { $method="2"; }
if ($ARGV[2]=~/\w/) { $del="$ARGV[2]";} else { $del=""; }

if ($error==0)
{
	my $experiment = XMLin("$filename_exp", forcearray=>[ 'group', 'sample', 'file' ]);
	my $local_dir="."; if ($filename_exp=~/^(.*)\/([^\/]+)$/) { $local_dir=$1; }
	$local_dir=~s/\\/\//g;
	my $local_dir_=$local_dir;
	$local_dir_=~s/\//\\/g;
	my $filename_exp_=$filename_exp;
	if ($filename_exp_=~/_step([0-9]+)\.xml$/i) { my $k=$1; $k++; $filename_exp_=~s/_step([0-9]+)\.xml$/_step$k.xml/i; } else { $filename_exp_=~s/\.xml$/_step1.xml/i; }
	if (open(OUT,">$filename_exp_"))
	{
		print OUT qq!<experiment>\n!;
		foreach my $group (@{$experiment->{group}})
		{
			my $group_id = $group->{id_};
			print OUT qq!\t<group id_="$group_id">\n!;
			foreach my $sample (@{$group->{sample}})
			{
				my $sample_id = $sample->{id_};
				print OUT qq!\t\t<sample id_="$sample_id">\n!;
				foreach my $file (@{$sample->{file}})
				{
					my $filename=$file->{path};
					if ($filename=~/\.mzXML$/i)
					{
						$filename=~s/^.*[\/\\]([^\/\\]+)$/$1/;
						#print qq!$filename\n!;
						foreach my $key(@method_)
						{
							my $method__="";
							$method__=$method." ".$key;  
							system(qq!D:\\Programs\\process_data\\mzXMLtoMGF "$local_dir/$filename" $method__!);
							if ($del=~/^del/) { system(qq!del "$local_dir_\\$filename"!); }
							$filename_=$filename;
							if ($method__=~/^([0-9]+)\s+([A-Zaz]+)\s*$/)
							{
								my $ms_level=$1;
								my $type=$2;
								$filename_=~s/\.mzXML$/.mzXML.MS$ms_level.$type.MGF/i;
								if( -z qq!$local_dir_\\$filename_!) { system(qq!del "$local_dir_\\$filename_"!);}
								else { print OUT qq!\t\t\t<file path="$local_dir/$filename_" />\n!; }
							}
						}
						system(qq!D:\\Programs\\process_data\\mzXMLtoMGF "$local_dir/$filename" 1!);
						my $filename__=$filename;
						$filename__=~s/\.mzXML$/.mzXML.MS1.MGF/i;
						system(qq!D:\\Programs\\process_data\\generate_base_peak_chromatogram.pl "$local_dir/$filename__"!);
					}
				}
				print OUT qq!\t\t</sample>\n!;
			}
			print OUT qq!\t</group>\n!;
		}
		print OUT qq!</experiment>\n!;
		close(OUT);
	}
}
