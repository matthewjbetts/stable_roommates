use strict;
use Test::More tests => 30;

BEGIN {
    use_ok('Matching::StableRoommates');
}

my $sr;
my $preferences;
my $n_pairs;
my @wrong;
my $n_wrong;
my $id;

$sr = eval {Matching::StableRoommates->new(n_pairs => 0, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with n_pairs = 0");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with empty preferences");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => [1, 2, 3]);};
ok(!$sr, "don't construct StableRoommates object with preferences given as a list");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {1 => [2, 3]});};
ok($sr, "construct StableRoommates object with integer ids");
ok(($sr->n_preferences(2) == 2), "no preferences for participant 2");
ok(($sr->proposals_to(1) == undef), "no accepted proposals for participant 1");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {'fred' => ['wilma', 'barney']});};
ok($sr, "construct StableRoommates object with string ids");

# example from http://en.wikipedia.org/wiki/Stable_roommates_problem
$preferences = {
                1 => [3, 4, 2, 6, 5],
                2 => [6, 5, 4, 1, 3],
                3 => [2, 4, 5, 1, 6],
                4 => [5, 2, 3, 6, 1],
                5 => [3, 1, 2, 4, 6],
                6 => [5, 1, 3, 4, 2],
               };
$n_pairs = 1;
$sr = eval {Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences);};
ok($sr, "construct StableRoommates object for example 1");
ok(($sr->n_preferences(1) == 5), "five preferences for participant 1");
ok(($sr->proposals_to(1) == undef), "no accepted proposals for participant 1");
ok(($sr->ranking(1, 3) == 0), "participant 3 is at rank 0 in participant 1's preference list");
ok(($sr->ranking(4, 6) == 3), "participant 6 is at rank 3 in participant 4's preference list");
ok($sr->phase1(), 'phase1');
ok($sr->phase2(), 'phase2');
ok($sr->stable(), 'stable pairing found');

# Irving's example for which no stable matching is possible
$preferences = {
                1 => [2, 3, 4],
                2 => [3, 1, 4],
                3 => [1, 2, 4],
                # 4 has no specified preferences
               };
$n_pairs = 1;
$sr = eval {Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences);};
ok(($sr->phase1() == 0), 'no stable pairing possible');
ok(($sr->stable() == 0), 'no stable pairing found');

# first example in Irving section 2
$preferences = {
                1 => [4, 6, 2, 5, 3],
                2 => [6, 3, 5, 1, 4],
                3 => [4, 5, 1, 6, 2],
                4 => [2, 6, 5, 1, 3],
                5 => [4, 2, 3, 6, 1],
                6 => [5, 1, 4, 2, 3],
               };
$n_pairs = 1;
$sr = eval {Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences);};
ok($sr->phase1(), 'phase1');
ok($sr->phase2(), 'phase2');
ok($sr->stable(), 'stable pairing found');
ok(($sr->proposals_to(1) == 6), '1 <- 6 found');
ok(($sr->proposals_to(2) == 3), '2 <- 3 found');
ok(($sr->proposals_to(3) == 2), '3 <- 2 found');
ok(($sr->proposals_to(4) == 5), '4 <- 5 found');
ok(($sr->proposals_to(5) == 4), '5 <- 4 found');
ok(($sr->proposals_to(6) == 1), '6 <- 1 found');

# last example in Irving
$preferences = {
                1 => [2, 6, 4, 3, 5],
                2 => [3, 5, 1, 6, 4],
                3 => [1, 6, 2, 5, 4],
                4 => [5, 2, 3, 6, 1],
                5 => [6, 1, 3, 4, 2],
                6 => [4, 2, 5, 1, 3],
               };
$n_pairs = 1;
$sr = eval {Matching::StableRoommates->new(n_pairs => $n_pairs, preferences => $preferences);};
ok($sr->phase1(), 'phase1');
ok(($sr->phase2() == 0), 'phase2 failed');
ok(($sr->stable() == 0), 'no stable pairing found');
