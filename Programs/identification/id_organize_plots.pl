#!c:/perl64/bin/perl.exe

$dir=$ARGV[0];
$dir=~s/\\/\//g;
$dir_=$dir;
$dir_=~s/\//\\/g;
$dir__=$dir;
$dir__=~s/^.*\/([^\/]+)$/$1/;
mkdir("$dir/plots");
mkdir("$dir/plots/id");
mkdir("$dir/plots/id/before_cal");
mkdir("$dir/plots/id/after_cal");
mkdir("$dir/plots/id/before_alignment");
system(qq!move "$dir_\\*.align.png" "$dir_\\plots\\id\\before_alignment"!);

if (opendir(dir,"$dir"))
{
	my @allfiles=readdir dir;
	closedir dir;
	foreach $filename (@allfiles)
	{
		if ($filename=~/\.([0-9]+\.?[0-9]+[edED][\+\-][0-9]+)\.png$/i) { $expect{"$1"}=1; }
		else
		{
			if ($filename=~/\.([0-9]+[edED][\+\-][0-9]+)\.png$/i) { $expect{"$1"}=1; }
			else
			{
				if ($filename=~/\.([0-9]+\.[0-9]+)\.png$/i) { $expect{"$1"}=1; }
				else
				{
					if ($filename=~/\.([0-9]+)\.png$/i) { $expect{"$1"}=1; }
				}
			}
		}
	}
}
# foreach $expect (keys %expect)
# {
	# $expect_=$expect;
	# $expect_=~s/^\.*//;
	# print qq!$expect_\n!;
	# mkdir("$dir/plots/id/before_cal/$expect_");
	# mkdir("$dir/plots/id/after_cal/$expect_");
	
	mkdir("$dir/plots/id/before_cal");
	mkdir("$dir/plots/id/after_cal");
	
	system(qq!move "$dir_\\*.png" "$dir_\\plots\\id\\before_cal"!);  #### changes ####
	system(qq!move "$dir_\\plots\\id\\before_cal\\*cal.png" "$dir_\\plots\\id\\after_cal"!);   #### changes ####
	
	# system(qq!move "$dir_\\*$expect.png" "$dir_\\plots\\id\\before_cal\\$expect_"!);
	# system(qq!move "$dir_\\plots\\id\\before_cal\\$expect_\\*cal.$expect.png" "$dir_\\plots\\id\\after_cal\\$expect_"!);

# }