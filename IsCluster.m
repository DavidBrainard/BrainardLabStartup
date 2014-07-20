function [isCluster,whichCluster] =  IsCluster
% [isCluster,whichCluster] = IsCluster
%
% Is this one of our clusters, and if so which one?
%
% The only linux machines we use are the clusters hippo and rhino.  On hippo, we always use
% an account named 'brainard', and on rhino we never do.  So once we establish it is linux,
% checking the username tells us which cluster.  You might think we could do this by checking
% the hostname, but the nodes have names like 'nodeX' on the clusters, so that is hard.  If
% we ever take on more linux machines this conditional will have to be
% rethought .
%
% 6/10/09  dhb  Wrote it.
% 3/23/10  dhb  Make help match what function  returns.

% Set default response
isCluster = 0;
whichCluster = '';

% Is it a cluster?
if (strcmp(computer,'GLNXA64'))
    isCluster = 1;
    
    % Figure out which cluster
    [nil, host] = unix('hostname');
    [nil, theUser] = unix('whoami');  
    if (length(theUser) < 8 | ~strcmp(theUser(1:8),'brainard'))
        whichCluster = 'rhino';
    else
        whichCluster = 'hippo';
    end
end