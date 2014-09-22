* phase2: eliminate the rotation
* if the n_pairs >= n_pairs_max, then everyone can be paired with everyone else
* allow for multiple rounds, not just one set of pairings
* need to make sure that at each date round, all pairs are stable
* use Carp::cluck and Carp::croak for warnings, and/or 'die' and 'eval'
* report whether or not a stable matching is possible
