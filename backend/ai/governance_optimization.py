# backend/ai/governance_optimization.py
import tensorflow as tf
import numpy as np
from typing import Dict, List
from .models import GovernanceModel
from .data_processors import GovernanceDataProcessor

class GovernanceOptimizer:
    def __init__(self):
        self.model = self._build_model()
        self.data_processor = GovernanceDataProcessor()
        
    def _build_model(self) -> tf.keras.Model:
        return GovernanceModel(
            layers=[
                tf.keras.layers.Dense(128, activation='relu'),
                tf.keras.layers.Dropout(0.3),
                tf.keras.layers.Dense(64, activation='relu'),
                tf.keras.layers.Dense(32, activation='relu'),
                tf.keras.layers.Dense(16, activation='softmax')
            ]
        )
    
    async def optimize_parameters(
        self,
        dao_data: Dict,
        historical_data: List[Dict]
    ) -> Dict:
        # Process input data
        processed_data = self.data_processor.process_data(
            dao_data,
            historical_data
        )
        
        # Generate optimization predictions
        predictions = self.model.predict(processed_data)
        
        # Convert predictions to governance parameters
        optimized_params = self._convert_predictions(predictions)
        
        # Validate parameters
        self._validate_parameters(optimized_params)
        
        return optimized_params
    
    def _convert_predictions(
        self,
        predictions: np.ndarray
    ) -> Dict:
        return {
            'voting_period': int(predictions[0] * 100000),
            'quorum_requirement': float(predictions[1]),
            'proposal_threshold': int(predictions[2] * 1000),
            'voting_delay': int(predictions[3] * 10000),
            'execution_delay': int(predictions[4] * 10000),
            'voting_power_strategy': self._get_voting_strategy(predictions[5])
        }
    
    def _get_voting_strategy(
        self,
        prediction: float
    ) -> str:
        strategies = [
            'quadratic',
            'linear',
            'conviction',
            'holographic',
            'adaptive'
        ]
        return strategies[int(prediction * len(strategies))]