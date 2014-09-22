* if the n_pairs >= n_pairs_max, then everyone can be paired with everyone else
* allow for multiple rounds, not just one set of pairings
* need to make sure that at each date round, all pairs are stable
* use Carp::cluck and Carp::croak for warnings, and/or 'die' and 'eval'
* meaningful error or status reports, especially for perference list for which no stable matching is possible
* if all by all is possible with the desired number of rounds, list the pairings in each round
* allow multiple rounds of stable roommates, ignoring pairs from previous rounds
* module to assign random pairs, when no stable pairing is possible
