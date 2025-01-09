// frontend/src/components/Dashboard/index.tsx
import React, { useState, useEffect } from 'react';
import { 
    Grid, 
    Card, 
    Typography, 
    Box, 
    Tabs, 
    Tab 
} from '@material-ui/core';
import {
    ProposalList,
    TokenMetrics,
    GovernanceStats,
    MemberDirectory,
    ActivityFeed,
    Treasury,
    Analytics
} from './components';
import { useDAO, useWeb3 } from '../../hooks';
import { DashboardProvider } from './context';

interface DashboardProps {
    daoAddress: string;
}

export const Dashboard: React.FC<DashboardProps> = ({ daoAddress }) => {
    const [activeTab, setActiveTab] = useState(0);
    const { dao, loading, error } = useDAO(daoAddress);
    const { account, chainId } = useWeb3();

    const handleTabChange = (event: React.ChangeEvent<{}>, newValue: number) => {
        setActiveTab(newValue);
    };

    if (loading) return <LoadingSpinner />;
    if (error) return <ErrorMessage message={error} />;

    return (
        <DashboardProvider>
            <Box p={3}>
                <Grid container spacing={3}>
                    <Grid item xs={12}>
                        <DaoHeader dao={dao} />
                    </Grid>
                    
                    <Grid item xs={12}>
                        <Tabs value={activeTab} onChange={handleTabChange}>
                            <Tab label="Overview" />
                            <Tab label="Proposals" />
                            <Tab label="Treasury" />
                            <Tab label="Members" />
                            <Tab label="Analytics" />
                        </Tabs>
                    </Grid>

                    <Grid item xs={12}>
                        {activeTab === 0 && (
                            <Overview 
                                tokenMetrics={dao.tokenMetrics}
                                governanceStats={dao.governanceStats}
                                recentActivity={dao.recentActivity}
                            />
                        )}
                        {activeTab === 1 && (
                            <ProposalManager 
                                proposals={dao.proposals}
                                userVotingPower={dao.votingPower[account]}
                            />
                        )}
                        {activeTab === 2 && (
                            <TreasuryManager 
                                assets={dao.treasury}
                                permissions={dao.permissions[account]}
                            />
                        )}
                        {activeTab === 3 && (
                            <MemberManager 
                                members={dao.members}
                                roles={dao.roles}
                            />
                        )}
                        {activeTab === 4 && (
                            <AnalyticsPanel 
                                metrics={dao.metrics}
                                timeframe="1M"
                            />
                        )}
                    </Grid>
                </Grid>
            </Box>
        </DashboardProvider>
    );
};