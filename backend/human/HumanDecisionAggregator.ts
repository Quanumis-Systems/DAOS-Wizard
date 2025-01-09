// backend/human/HumanDecisionAggregator.ts
class HumanDecisionAggregator {
    private consensusEngine: ConsensusEngine;
    private decisionTracker: DecisionTracker;
    private wisdomDistiller: WisdomDistiller;

    async aggregateDecisions(
        decisions: HumanDecision[],
        context: DecisionContext
    ): Promise<CollectiveDecision> {
        // Track individual human inputs
        const trackedDecisions = await this.decisionTracker
            .trackDecisions(decisions);

        // Build consensus
        const consensus = await this.consensusEngine
            .buildConsensus(trackedDecisions);

        // Distill collective wisdom
        const wisdom = await this.wisdomDistiller
            .distillWisdom(consensus);

        return {
            decision: consensus,
            rationale: wisdom.rationale,
            impact: wisdom.impact,
            template: await this.createDecisionTemplate(wisdom)
        };
    }
}