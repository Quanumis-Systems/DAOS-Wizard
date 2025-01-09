# backend/api/dao_manager.py
from typing import Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from web3 import Web3
from eth_account import Account
from sqlalchemy.orm import Session

from .models import DAO, Proposal, Member, Transaction
from .schemas import DAOCreate, ProposalCreate, VoteCreate
from .services import (
    TokenService,
    GovernanceService,
    IPFSService,
    NotificationService,
    AnalyticsService
)

app = FastAPI()

# Services initialization
token_service = TokenService()
governance_service = GovernanceService()
ipfs_service = IPFSService()
notification_service = NotificationService()
analytics_service = AnalyticsService()

@app.post("/dao/create")
async def create_dao(dao_data: DAOCreate, db: Session):
    try:
        # Store DAO metadata on IPFS
        metadata_hash = await ipfs_service.store_metadata(dao_data.metadata)
        
        # Deploy token contract
        token_address = await token_service.deploy_token(
            dao_data.token_config,
            dao_data.owner_address
        )
        
        # Deploy governance contract
        governance_address = await governance_service.deploy_governance(
            dao_data.governance_config,
            token_address
        )
        
        # Create DAO record
        dao = DAO(
            name=dao_data.name,
            metadata_hash=metadata_hash,
            token_address=token_address,
            governance_address=governance_address,
            creator_address=dao_data.owner_address
        )
        
        db.add(dao)
        db.commit()
        
        # Initialize analytics tracking
        analytics_service.initialize_dao_metrics(dao.id)
        
        # Send notifications
        notification_service.notify_dao_creation(dao)
        
        return {"success": True, "dao_id": dao.id}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/dao/{dao_id}/proposal")
async def create_proposal(
    dao_id: int,
    proposal_data: ProposalCreate,
    db: Session
):
    dao = db.query(DAO).filter(DAO.id == dao_id).first()
    if not dao:
        raise HTTPException(status_code=404, detail="DAO not found")
    
    # Store proposal content on IPFS
    content_hash = await ipfs_service.store_content(proposal_data.content)
    
    # Create on-chain proposal
    proposal_id = await governance_service.create_proposal(
        dao.governance_address,
        proposal_data
    )
    
    # Create proposal record
    proposal = Proposal(
        dao_id=dao_id,
        proposal_id=proposal_id,
        content_hash=content_hash,
        creator_address=proposal_data.creator_address,
        status="active"
    )
    
    db.add(proposal)
    db.commit()
    
    # Notify stakeholders
    notification_service.notify_new_proposal(proposal)
    
    return {"success": True, "proposal_id": proposal_id}

@app.get("/dao/{dao_id}/analytics")
async def get_dao_analytics(dao_id: int, timeframe: str = "1M"):
    metrics = await analytics_service.get_dao_metrics(dao_id, timeframe)
    return metrics