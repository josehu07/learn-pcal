---- MODULE MultiPaxos_MC ----
EXTENDS MultiPaxos

SymmetricPerms ==      Permutations(Replicas)
                  \cup Permutations(Values)
                  \cup Permutations(Slots)

ConstBallots == 0..1

----------

(*************************)
(* Type check invariant. *)
(*************************)
StatusSet == {"", "Preparing", "Accepting", "Learned"}

SlotVotes == [Slots -> [bal: Ballots \cup {-1},
                        val: Values \cup {0}]]

Messages ==      [type: {"Prepare"}, from: Replicas,
                                     bal: Ballots]
            \cup [type: {"PrepareReply"}, from: Replicas,
                                          bal: Ballots,
                                          voted: SlotVotes]
            \cup [type: {"Accept"}, from: Replicas,
                                    slot: Slots,
                                    bal: Ballots,
                                    val: Values]
            \cup [type: {"AcceptReply"}, from: Replicas,
                                         slot: Slots,
                                         bal: Ballots,
                                         val: Values]

TypeOK == /\ msgs \in SUBSET Messages
          /\ lBallot \in [Replicas -> Ballots \cup {-1}]
          /\ lStatus \in [Replicas -> [Slots -> StatusSet]]
          /\ rBallot \in [Replicas -> Ballots \cup {-1}]
          /\ rVoted \in [Replicas -> SlotVotes]
          /\ proposed \in [Slots -> SUBSET Values]
          /\ learned \in [Slots -> SUBSET Values]

THEOREM Spec => []TypeOK

----------

(*****************************************************************************)
(* Check that it implements the ConsensusMulti spec. This transitively means *)
(* that it satisfies the following three properties:                         *)
(*   - Nontriviality                                                         *)
(*   - Stability                                                             *)
(*   - Consistency                                                           *)
(*                                                                           *)
(* Only check this property on very small model constants inputs, otherwise  *)
(* it would take a prohibitively long time due to state bloating.            *)
(*****************************************************************************)
proposedSet == UNION {proposed[s]: s \in Slots}

ConsensusModule == INSTANCE ConsensusMulti WITH proposed <- proposedSet,
                                                chosen <- learned
ConsensusSpec == ConsensusModule!Spec

THEOREM Spec => ConsensusSpec

----------

(********************************************************************************)
(* The non-triviality and consistency properties stated in invariant flavor.    *)
(* The stability property cannot be stated as an invariant.                     *)
(*                                                                              *)
(* Checking invariants takes significantly less time than checking more complex *)
(* temporal properties. Hence, first check these as invariants on larger        *)
(* constants inputs, then check the ConsensusSpec property on small inputs.     *)
(********************************************************************************)
NontrivialityInv ==
    \A s \in Slots: \A v \in learned[s]: v \in proposed[s]

ConsistencyInv ==
    \A s \in Slots: Cardinality(learned[s]) =< 1

THEOREM Spec => [](NontrivialityInv /\ ConsistencyInv)

====