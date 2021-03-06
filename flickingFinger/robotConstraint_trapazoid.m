function [c, ceq, gc, gceq] = robotConstraint_trapazoid(dt,z,x0,xF,nGrid,nState,nControl,nContactForce,p)

nZ = nState*nGrid + nControl*nGrid + nContactForce*nGrid;
stateIdx = 1:nState*nGrid;
controlIdx = nState*nGrid+1:nState*nGrid + nControl*nGrid;
forceIdx = nState*nGrid+nControl*nGrid+1:nZ;

x = reshape(z(stateIdx),nState,nGrid); 
u = reshape(z(controlIdx),nControl,nGrid);
contact = reshape(z(forceIdx),nContactForce,nGrid);

dim_boundary_cst = 9;
dim_ceq = 6;
dim_c = 12;

% ceq = zeros(6+(nGrid-1)*dim_ceq,1);
ceq = zeros(dim_boundary_cst+(nGrid-1)*dim_ceq,1);
c   = zeros(nGrid*dim_c,1);

gceq = zeros(nZ,dim_boundary_cst+(nGrid-1)*dim_ceq);
gc = zeros(nZ,nGrid*dim_c);


ceq(1:6) = (x(:,1)-x0).^2;
ceq(7:9) = (x(1:3,end)-xF(1:3)).^2;
gceq(1:6,1:6) = diag((2*(x(:,1)-x0)));
gceq(nState*(nGrid-1)+1:nState*(nGrid-1)+3,7:9) = diag(2*(x(1:3,end)-xF(1:3)));


for idxUpp = 2:nGrid
    idxLow = idxUpp - 1;
    qk    = x(1:3,idxLow);
    dqk   = x(4:6,idxLow);
    
    qk1  = x(1:3,idxUpp);
    dqk1 = x(4:6,idxUpp);  

    % p stands for "part"
    [pc,~,pcz,pczi,~] = autoGen_c_grad(dt,qk(1),qk(2),qk(3),...
                                       dqk(1),dqk(2),dqk(3),...
                                       qk1(1),qk1(2),qk1(3),...
                                       dqk1(1),dqk1(2),dqk1(3),...
                                       u(1,idxUpp),u(2,idxUpp),...
                                       contact(1,idxLow),contact(2,idxLow),contact(3,idxLow),contact(4,idxLow),...
                                       contact(1,idxUpp),contact(2,idxUpp),contact(3,idxUpp),contact(4,idxUpp),0);
    
    [pceq,~,pceqz,pceqzi,~] = autoGen_ceq_grad(dt,qk(1),qk(2),qk(3),...
                                               dqk(1),dqk(2),dqk(3),...
                                               qk1(1),qk1(2),qk1(3),...
                                               dqk1(1),dqk1(2),dqk1(3),...
                                               u(1,idxUpp),u(2,idxUpp),...
                                               contact(1,idxLow),contact(2,idxLow),contact(3,idxLow),contact(4,idxLow),...
                                               contact(1,idxUpp),contact(2,idxUpp),contact(3,idxUpp),contact(4,idxUpp),0);
%     size(pc)
    
                                        
    ceq(dim_boundary_cst+(idxUpp-2)*dim_ceq+1:dim_boundary_cst+(idxUpp-2)*dim_ceq+dim_ceq) = pceq;  
    c((idxUpp-2)*dim_c+1:(idxUpp-2)*dim_c+dim_c) = pc;
    

        % assemble idices 
        idx = [nState*(idxLow-1)+1:nState*idxUpp  nState*nGrid+nControl*(idxLow-1)+1:nState*nGrid+nControl*idxLow nState*nGrid+nControl*nGrid+nContactForce*(idxLow-1)+1:nState*nGrid+nControl*nGrid+nContactForce*idxUpp];
        
        k2 = zeros(dim_c,22);
        k2(pczi) = real(pcz);
        gc(idx,(idxUpp-2)*dim_c+1:(idxUpp-2)*dim_c+dim_c) = k2';
               
        k = zeros(dim_ceq,22);
        k(pceqzi) = real(pceqz);
        gceq(idx,dim_boundary_cst+(idxUpp-2)*dim_ceq+1:dim_boundary_cst+(idxUpp-2)*dim_ceq+dim_ceq) = k';
end

% c has an additional step for the last tiem instance
idFinal = nGrid;
qk    = x(1:3,idFinal);
dqk   = x(4:6,idFinal);
qk1  = x(1:3,idFinal);
dqk1 = x(4:6,idFinal);  
[pc,~,pcz,pczi,~] = autoGen_c_grad(dt,qk(1),qk(2),qk(3),...
                                   dqk(1),dqk(2),dqk(3),...
                                   qk1(1),qk1(2),qk1(3),...
                                   dqk1(1),dqk1(2),dqk1(3),...
                                   u(1,idFinal),u(2,idFinal),...
                                   contact(1,idFinal),contact(2,idFinal),contact(3,idFinal),contact(4,idFinal),...
                                   contact(1,idFinal),contact(2,idFinal),contact(3,idFinal),contact(4,idFinal),0);
c((idFinal-1)*dim_c+1:(idFinal-1)*dim_c+dim_c) = pc;
idx = [nState*(idFinal-1)+1:nState*idFinal  nState*nGrid+nControl*(idFinal-1)+1:nState*nGrid+nControl*idFinal nState*nGrid+nControl*nGrid+nContactForce*(idFinal-1)+1:nState*nGrid+nControl*nGrid+nContactForce*idFinal];
k2 = zeros(dim_c,22);
k2(pczi) = real(pcz);
k2 = k2(:,[1:6,13:14,15:18]);
gc(idx,(idFinal-1)*dim_c+1:(idFinal-1)*dim_c+dim_c) = k2';
    
% gceq = gceq';
% gc = gc';
end