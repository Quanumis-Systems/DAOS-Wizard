# backend/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from web3 import Web3
from database.models import db, DAO
from blockchain.deployer import SmartContractDeployer

app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///daos.db'
db.init_app(app)

@app.route('/api/dao/create', methods=['POST'])
def create_dao():
    try:
        data = request.json
        
        # Deploy smart contracts
        deployer = SmartContractDeployer()
        contract_addresses = deployer.deploy_dao(
            data['tokenConfig'],
            data['governanceConfig']
        )
        
        # Store DAO information
        new_dao = DAO(
            name=data['name'],
            description=data['description'],
            token_address=contract_addresses['token'],
            governance_address=contract_addresses['governance']
        )
        
        db.session.add(new_dao)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'dao': new_dao.to_dict(),
            'contracts': contract_addresses
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/dao/<dao_id>', methods=['GET'])
def get_dao(dao_id):
    dao = DAO.query.get(dao_id)
    return jsonify(dao.to_dict())

if __name__ == '__main__':
    app.run(debug=True)