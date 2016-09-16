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
	my $experiment = XMLin("$filename_exp", forcearray=>[ 'group', 'sample', 'file' ]);
	my $local_dir="."; if ($filename_exp=~/^(.*)[\/\\]([^\/\\]+)$/) { $local_dir=$1; }
	$local_dir=~s/\\/\//g;
	my $local_dir_=$local_dir;
	$local_dir_=~s/\//\\/g;
	my $filename_exp_=$filename_exp;
	if ($filename_exp_=~/_step([0-9]+)\.xml$/i) { my $k=$1; $k++; $filename_exp_=~s/_step([0-9]+)\.xml$/_step$k.xml/i; } else { $filename_exp_=~s/\.xml$/_step1.xml/i; }
	my $filename_exp__=$filename_exp_;
	$filename_exp__=~s/\//\\/g;
	if (open(BAT,">$filename_exp_.bat"))
	{
		print BAT qq!cd D:\\Server\\thegpm\\thegpm-cgi\nd:\n!;
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
						if ($filename=~/\.mzXML$/i or $filename=~/\.MGF$/i)
						{
							$filename=~s/^.*[\/\\]([^\/\\]+)$/$1/;
							my $filename_=$filename;
							$filename_=~s/\.mzXML$/.xml/i;
							$filename_=~s/\.MGF$/.xml/i;
							#print qq!$filename\n!;
							if (open(MET,"$method"))
							{
								if (open(OUT_,">$local_dir/input_$filename_"))
								{
									while($line=<MET>)
									{
										$line=~s/\<note type=\"input\" label=\"spectrum\, path\"\>.*\<\/note\>/\<note type=\"input\" label=\"spectrum\, path\"\>$local_dir\/$filename\<\/note\>/;
										$line=~s/\<note type=\"input\" label=\"output\, title\"\>.*\<\/note\>/\<note type=\"input\" label=\"output\, title\"\>$filename\<\/note\>/;
										$line=~s/\<note type=\"input\" label=\"output\, path\"\>.*\<\/note>/\<note type=\"input\" label=\"output\, path\"\>$local_dir\/$filename_\<\/note\>/;
										$line=~s/\<note type=\"input\" label=\"spectrum\, threads\"\>.*\<\/note>//;
										if ($line=~/\<\/bioml\>/) { print OUT_ qq!<note type="input" label="spectrum, threads">$SETTINGS{'Tandem_threads'}</note>\n!; }
										print OUT_ $line;
									}
									close(OUT_);
								}
								close(MET);
							}
							print BAT qq!xhunter.exe "$local_dir/input_$filename_"\n!;
							#print BAT qq!del "$local_dir_\\input_$filename_"\n!;
							if ($del=~/^del/) { print BAT qq!del "$local_dir_\\input_$filename_\n"!; }
							print OUT qq!\t\t\t<file path="$local_dir/$filename_" />\n!;
						}
					}
					print OUT qq!\t\t</sample>\n!;
				}
				print OUT qq!\t</group>\n!;
			}
			print OUT qq!</experiment>\n!;
			close(OUT);
		}
		close(BAT); 
		#print qq!***$path\\$filename_exp__.bat---\n!;
		system(qq!$filename_exp_.bat!);
		system(qq!del $filename_exp__.bat!);
	}
}
