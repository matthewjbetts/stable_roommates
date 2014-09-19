use strict;
use Test::More tests => 13;

BEGIN {
    use_ok('Matching::StableRoommates');
}

my $sr;

$sr = eval {Matching::StableRoommates->new(n_pairs => 0, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with n_pairs = 0");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {});};
ok(!$sr, "don't construct StableRoommates object with empty preferences");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => [1, 2, 3]);};
ok(!$sr, "don't construct StableRoommates object with preferences given as a list");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {1 => [2, 3]});};
ok($sr, "construct StableRoommates object with integer ids");
ok(($sr->n_preferences(2) == 0), "no preferences for participant 2");
ok(($sr->n_proposals(1) == 0), "no accepted proposals for participant 1");

$sr = eval {Matching::StableRoommates->new(n_pairs => 1, preferences => {'fred' => ['wilma', 'barney']});};
ok($sr, "construct StableRoommates object with string ids");

$sr = eval {
    Matching::StableRoommates->new(
                                   n_pairs     => 1,
                                   preferences => {
                                                   1 => [3, 4, 2, 6, 5],
                                                   2 => [6, 5, 4, 1, 3],
                                                   3 => [2, 4, 5, 1, 6],
                                                   4 => [5, 2, 3, 6, 1],
                                                   5 => [3, 1, 2, 4, 6],
                                                   6 => [5, 1, 3, 4, 2],
                                                  },
                                   debug       => 1,
                                  );
};
ok($sr, "construct StableRoommates object for example 1");
ok(($sr->n_preferences(1) == 5), "five preferences for participant 1");
ok(($sr->n_proposals(1) == 0), "no accepted proposals for participant 1");
ok(($sr->ranking(1, 3) == 0), "participant 3 is at rank 0 in participant 1's preference list");
ok(($sr->ranking(4, 6) == 3), "participant 6 is at rank 3 in participant 4's preference list");

$sr->phase1();
