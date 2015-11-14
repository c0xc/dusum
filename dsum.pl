#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Find;
use Data::Dumper;

# Options
my $_quiet;
my $_bytes;
my $_count;
my $_dots = 50;
GetOptions(
    "quiet" => \$_quiet,
    "bytes" => \$_bytes,
    "count" => \$_count,
    "dots=i" => \$_dots,
) or die "Error in command line arguments\n";

# Scan current directory by default
my @dirs = @ARGV;
@dirs = ('.') unless @dirs;

# Exit code
my $code = 0;

# Loop through dirs
for my $dir (@dirs)
{
    if (! -d $dir)
    {
        print STDERR "Not a directory: $dir\n";
        $code++;
        next;
    }

    # Find files
    my $files = [];
    find({ wanted => sub { push @$files, $_ if -f $_ }, no_chdir => 1}, $dir);
    @$files = grep({! -l $_} @$files);

    # Get sizes
    my $total_size = 0;
    my $i = 0;
    for my $file (@$files)
    {
        # Get size
        my $size = (stat($file))[7];
        if (!defined($size))
        {
            print STDERR "Error determining file size: $file\n";
            $code++;
            next;
        }

        # Add
        $total_size += $size;

    }

    # Format size
    my $human_string;
    my $converted_size = $total_size;
    my $converted_suffix;
    my $factor = 1024;
    for (qw(K M G))
    {
        if ($converted_size >= $factor)
        {
            $converted_size /= $factor;
            $converted_suffix = $_;
        }
        else
        {
            last;
        }
    }
    if ($converted_suffix)
    {
        $human_string = sprintf("%.2f ${converted_suffix}B", $converted_size);
    }

    # Summary string (per directory)
    my $string;
    if ($human_string && !$_bytes)
    {
        $string = "$human_string";
    }
    else
    {
        $string = "$total_size B";
    }
    if ($_count)
    {
        $string .= ", ".@$files." files";
    }
    print $string.' '.('.' x ($_dots - length($string))).' '.$dir."\n";

}

exit $code;
