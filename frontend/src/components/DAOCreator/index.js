// frontend/src/components/DAOCreator/index.js
import { useState } from 'react';
import { Stepper, Step, StepLabel, Button, Typography } from '@material-ui/core';
import {
  BasicInfo,
  TokenConfig,
  GovernanceSetup,
  ReviewAndDeploy
} from './steps';

const steps = [
  'Basic Information',
  'Token Configuration',
  'Governance Setup',
  'Review & Deploy'
];

function DAOCreator() {
  const [activeStep, setActiveStep] = useState(0);
  const [daoConfig, setDaoConfig] = useState({
    name: '',
    description: '',
    tokenConfig: {},
    governanceConfig: {}
  });

  const handleNext = () => {
    setActiveStep((prev) => prev + 1);
  };

  const handleBack = () => {
    setActiveStep((prev) => prev - 1);
  };

  const handleDaoConfigUpdate = (update) => {
    setDaoConfig((prev) => ({ ...prev, ...update }));
  };

  const getStepContent = (step) => {
    switch (step) {
      case 0:
        return <BasicInfo config={daoConfig} onUpdate={handleDaoConfigUpdate} />;
      case 1:
        return <TokenConfig config={daoConfig} onUpdate={handleDaoConfigUpdate} />;
      case 2:
        return <GovernanceSetup config={daoConfig} onUpdate={handleDaoConfigUpdate} />;
      case 3:
        return <ReviewAndDeploy config={daoConfig} />;
      default:
        return 'Unknown step';
    }
  };

  return (
    <div>
      <Stepper activeStep={activeStep}>
        {steps.map((label) => (
          <Step key={label}>
            <StepLabel>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>
      <div>
        {activeStep === steps.length ? (
          <div>
            <Typography>All steps completed - DAO is ready!</Typography>
          </div>
        ) : (
          <div>
            {getStepContent(activeStep)}
            <div>
              <Button disabled={activeStep === 0} onClick={handleBack}>
                Back
              </Button>
              <Button variant="contained" color="primary" onClick={handleNext}>
                {activeStep === steps.length - 1 ? 'Deploy DAO' : 'Next'}
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default DAOCreator;