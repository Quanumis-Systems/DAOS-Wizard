# backend/services/analytics_service.py
from typing import Dict, Any
import pandas as pd
from web3 import Web3
from .database import Database
from .metrics import MetricsCalculator

class AnalyticsService:
    def __init__(self):
        self.db = Database()
        self.metrics_calculator = MetricsCalculator()
        self.web3 = Web3()

    async def get_dao_metrics(self, dao_id: int, timeframe: str) -> Dict[str, Any]:
        # Fetch raw data
        proposals = await self.db.get_dao_proposals(dao_id)
        votes = await self.db.get_dao_votes(dao_id)
        transactions = await self.db.get_dao_transactions(dao_id)
        token_transfers = await self.db.get_token_transfers(dao_id)
        
        # Calculate metrics
        metrics = {
            "governance": self._calculate_governance_metrics(proposals, votes),
            "financial": self._calculate_financial_metrics(transactions),
            "community": self._calculate_community_metrics(token_transfers),
            "activity": self._calculate_activity_metrics(proposals, votes, transactions)
        }
        
        # Calculate trends
        trends = self._calculate_trends(metrics, timeframe)
        
        # Generate insights
        insights = self._generate_insights(metrics, trends)
        
        return {
            "metrics": metrics,
            "trends": trends,
            "insights": insights,
            "timeframe": timeframe
        }

    def _calculate_governance_metrics(self, proposals, votes):
        return {
            "proposal_count": len(proposals),
            "vote_participation": self.metrics_calculator.calculate_participation(votes),
            "proposal_success_rate": self.metrics_calculator.calculate_success_rate(proposals),
            "voter_distribution": self.metrics_calculator.calculate_voter_distribution(votes),
            "delegation_patterns": self.metrics_calculator.analyze_delegations(votes)
        }

    def _calculate_financial_metrics(self, transactions):
        return {
            "treasury_value": self.metrics_calculator.calculate_treasury_value(transactions),
            "daily_volume": self.metrics_calculator.calculate_volume(transactions, "daily"),
            "token_velocity": self.metrics_calculator.calculate_token_velocity(transactions),
            "holder_distribution": self.metrics_calculator.calculate_holder_distribution(transactions)
        }

    def _calculate_community_metrics(self, token_transfers):
        return {
            "active_members": self.metrics_calculator.calculate_active_members(token_transfers),
            "member_growth": self.metrics_calculator.calculate_member_growth(token_transfers),
            "engagement_score": self.metrics_calculator.calculate_engagement(token_transfers),
            "retention_rate": self.metrics_calculator.calculate_retention(token_transfers)
        }

    def _calculate_trends(self, metrics, timeframe):
        return {
            "governance_trends": self.metrics_calculator.calculate_metric_trends(
                metrics["governance"], 
                timeframe
            ),
            "financial_trends": self.metrics_calculator.calculate_metric_trends(
                metrics["financial"], 
                timeframe
            ),
            "community_trends": self.metrics_calculator.calculate_metric_trends(
                metrics["community"], 
                timeframe
            )
        }

    def _generate_insights(self, metrics, trends):
        return {
            "key_findings": self.metrics_calculator.generate_key_findings(metrics),
            "recommendations": self.metrics_calculator.generate_recommendations(metrics, trends),
            "risk_factors": self.metrics_calculator.analyze_risks(metrics, trends),
            "opportunities": self.metrics_calculator.identify_opportunities(metrics, trends)
        }