function [isCluster,whichCluster] =  IsCluster
% [isCluster,whichCluster] = IsCluster
%
% Is this one of our clusters, and if so which one?
%
% The only GLNXA64 linux machines we use are clusters, so checkling for
% Linux is currently sufficient.  Differentiating clusters is a bit
% harder because the nodes don't necessarily respond with the same
% hostname as the head node.
%
% 6/10/09  dhb  Wrote it.
% 3/23/10  dhb  Make help match what function returns.
% 4/9/16   dhb  Update for GPC.

% Set default response
isCluster = 0;
whichCluster = '';

% Is it a cluster?
if (strcmp(computer,'GLNXA64'))
    isCluster = 1;
    whichCluster = 'gpc';
end

% Figure out which cluster
% [nil, host] = unix('hostname');
% [nil, theUser] = unix('whoami');
% switch (host)
%     case 'rhino.psych.upenn.edu'
%         whichCluster = 'rhino';
%     case 'gpc'
%         whichCluster = 'gpc';
% end

end