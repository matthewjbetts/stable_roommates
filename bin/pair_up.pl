#!/usr/bin/perl -w

# Copyright 2014, Matthew Betts
#
# StableRoommates is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Matching::StableRoommates;

my $n_rounds;
my $n_rounds_max;
my $preferences;
my $preferences2;
my $participants;
my @F;
my $sr;
my $n_participants;
my $p;
my $round;
my $i;
my $j;
my $pairs_all;
my $pairs;
my $x;
my $y;

defined($n_rounds = shift @ARGV) or usage();

sub usage {
    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    die "Usage: $prog n_rounds < preferences\n";
}

$preferences = {};
$participants = {};
while(<STDIN>) {
    (/^#/ or /\A\s*\Z/) and next;
    @F = split;
    foreach $p (@F) {
        $participants->{$p}++;
    }
    $preferences->{$F[0]} = [@F[1..$#F]];
}
$participants = [sort keys %{$participants}];
$n_participants = scalar @{$participants};
$n_rounds_max = $n_participants - 1;

print <<END;

n_participants: $n_participants
n_rounds      : $n_rounds
n_rounds_max  : $n_rounds_max
END

($n_participants % 2) and die 'Error: even number of participants required.';

if($n_rounds >= $n_rounds_max) {
    print "\nall with all is possible\n\n";
    # if all by all is possible with the desired number of rounds, list the pairings in each round
}
else {
    $pairs = {};
    $pairs_all = {};
    for($round = 1; $round <= $n_rounds; $round++) {
        print "\n## round $round\n\n";

        # copy preferences, removing any pairs from previous rounds
        $preferences2 = {};
        foreach $x (keys %{$preferences}) {
            $preferences2->{$x} = [];
            foreach $y (@{$preferences->{$x}}) {
                defined($pairs_all->{$x}->{$y}) or push(@{$preferences2->{$x}}, $y);
            }
        }

        $sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => $preferences2);};
        defined($sr) or die 'could not construct Matching::StableRoommates object';

        if($sr->phase1) {
            if($sr->phase2) {
                #$sr->output();
                $pairs = $sr->pairs();
                output_pairs($pairs, $pairs_all);
            }
            else {
                print "failed phase2, pairing randomly instead\n\n";

                $pairs = random_pairing($participants, $pairs_all);
                output_pairs($pairs, $pairs_all);
             }
        }
        else {
            print "failed phase1, pairing randomly instead\n\n";

            $pairs = random_pairing($participants, $pairs_all);
            output_pairs($pairs, $pairs_all);
        }
    }
}

sub output_pairs {
    my($pairs, $pairs_all) = @_;

    my $x;
    my $y;

    foreach $x (sort keys %{$pairs}) {
        foreach $y (sort keys %{$pairs->{$x}}) {
            $pairs_all->{$x}->{$y}++;
            print "$x\t$y\n";
        }
    }
}

sub random_pairing {
    my($participants, $pairs_all) = @_;

    my $pairs;
    my $n_participants;
    my $i;
    my $x;
    my $y;

    $n_participants = scalar @{$participants};
    $pairs = {};
    for($i = 0; $i < $n_participants; $i++) {
        (scalar(keys(%{$pairs})) >= $n_participants) and last; # pairs are saved in both directions
        $x = $participants->[$i];
        defined($pairs->{$x}) and next;

        while(1) {
            $j = sprintf "%d", rand $n_participants;
            ($j == $i) and next;
            $y = $participants->[$j];

            # ignore participants that have already been paired
            # and ignore pairs found in previous rounds

            if(!defined($pairs->{$y}) and !defined($pairs_all->{$x}->{$y})) {
                $pairs->{$x}->{$y}++;
                $pairs->{$y}->{$x}++;
                last;
            }
        }
    }

    return $pairs;
}
