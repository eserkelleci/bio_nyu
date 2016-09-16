#!/usr/local/bin/perl
use XML::Simple;
use Data::Dumper;
use strict;

my $error=0;
my $filename_exp="";
my $method="";
my $del="";
my $line="";
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
my %programs=(); if (open(IN,"../programs.txt")) { while($line=<IN>) { if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) { $programs{"$1#$2"}=$3; } } close(IN); }

if ($ARGV[0]=~/\w/) { $filename_exp="$ARGV[0]";} else { $error=0; }
if ($ARGV[1]=~/\w/) { $method="$ARGV[1]";} else { $error=0; }
if ($ARGV[2]=~/\w/) { $del="$ARGV[2]";} else { $del=""; }

if ($error==0)
{
	my $filename_exp_=$filename_exp;
	if ($filename_exp_=~/_step([0-9]+)\.xml$/i) { $filename_exp_=~s/_step([0-9]+)\.xml$/_$method.xml/i; } else { $filename_exp_=~s/\.xml$/_$method.xml/i; }
	my $experiment = XMLin("$filename_exp_", forcearray=>[ 'group', 'sample', 'file' ]);
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
					$filename=~s/^.*[\/\\]([^\/\\]+)$/$1/;
					#print qq!$filename\n!;
					system(qq!del "$local_dir_\\$filename"!);
					my $filename_=$filename;
					print OUT qq!\t\t\t<file path="$local_dir/$filename_" />\n!;
				}
				print OUT qq!\t\t</sample>\n!;
			}
			print OUT qq!\t</group>\n!;
		}
		print OUT qq!</experiment>\n!;
		close(OUT);
	}
}
