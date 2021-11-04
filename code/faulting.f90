subroutine faulting

use globalvar
implicit none

!  
integer (kind=4)::ift, i,i1,j,k,n,isn,imn,loc(1)
real (kind = dp) ::slipn,slips,slipd,slip,slipraten,sliprates,sliprated,&
sliprate,xmu,mmast,mslav,mtotl,fnfault,fsfault,fdfault,tnrm,tstk, &
tdip,taox,taoy,taoz,ttao,taoc,ftix,ftiy,ftiz,trupt,tr,&
tmp1,tmp2,tmp3,tmp4,tnrm0,xmu1,xmu2

real (kind = dp) :: dtev1D(nftnd(1))
real (kind = dp),dimension(6,2,4)::fvd=0.0d0
real (kind = dp)::fa, fb, phi
real (kind = dp) :: rr,R0,T,dtao0,dtao,mr!RSF
real (kind = dp) :: statetmp, T_coeff!RSF
integer (kind=4) :: iv
real (kind = dp) :: tstk0, tdip0,ttao0, tstk1, tdip1, ttao1, taoc_old, taoc_new !RSF
real (kind = dp) :: dxmudv, rsfeq, drsfeqdv, vtmp
real (kind = dp) :: v_trial,v_trial_new,sliprs_trial,sliprd_trial, tau_fric_trial,&
	v_s_new_mast,v_s_new_slav,v_d_new_mast,v_d_new_slav,&
	uxm,uym,uzm,uxs,uys,uzs,&
	vxm,vym,vzm,vxs,vys,vzs,&
	axm,aym,azm,axs,ays,azs,&
	anm,asm,adm,ans,ass,ads,&
	slipratemast,sliprateslav,&
	slipaccn,slipaccs,slipaccd
real (kind = dp) :: ma_bar_ku_arr(nftnd(1)), sliprate_arr(nftnd(1)),momrate_arr(nftnd(1)),ruptarea_arr(nftnd(1)),taoruptarea_arr(nftnd(1)), &
                slipruptarea_arr(nftnd(1))

ruptarea_arr = 0.0d0
taoruptarea_arr = 0.0d0 
slipruptarea_arr = 0.0d0
do ift = 1, ntotft
	do i=1,nftnd(ift)	!just fault nodes
		fnfault = fric(7,i,ift) !initial forces on the fault node
		fsfault = fric(8,i,ift) !norm, strike, dip components directly
		if (icstart ==1) then
		  fdfault = 0.0d0
		else
		  fdfault = fric(49,i,ift)
		endif

		isn = nsmp(1,i,ift) 
		imn = nsmp(2,i,ift) 	

		do j=1,2  !1-slave, 2-master
			do k=1,3  !1-x comp, 2-y comp, 3-z comp
				fvd(k,j,1) = consf(k,nsmp(j,i,ift))  !1-force !DL 
				fvd(k,j,2) = consv(k,nsmp(j,i,ift)) !2-vel
				fvd(k,j,3) = cons(k,nsmp(j,i,ift)) !3-disp
				fvd(k,j,4) = consa(k,nsmp(j,i,ift)) !4-acc
			enddo
		enddo

		do j=1,4    !1-force,2-vel,3-disp,4-acc
			do k=1,2  !1-slave,2-master
				fvd(4,k,j) = fvd(1,k,j)*un(1,i,ift) + fvd(2,k,j)*un(2,i,ift) + fvd(3,k,j)*un(3,i,ift)  !4-norm
				fvd(5,k,j) = fvd(1,k,j)*us(1,i,ift) + fvd(2,k,j)*us(2,i,ift) + fvd(3,k,j)*us(3,i,ift)  !5-strike
				fvd(6,k,j) = fvd(1,k,j)*ud(1,i,ift) + fvd(2,k,j)*ud(2,i,ift) + fvd(3,k,j)*ud(3,i,ift)  !6-dip
			enddo
		enddo	

		slipn = fvd(4,2,3) - fvd(4,1,3)
		slips = fvd(5,2,3) - fvd(5,1,3)
		slipd = fvd(6,2,3) - fvd(6,1,3)
		slip = sqrt(slipn**2 + slips**2 + slipd**2) !slip mag
		fric(71,i,ift) = slips  !save for final slip output
		fric(72,i,ift) = slipd
		fric(73,i,ift) = slipn  !normal should be zero, but still keep to ensure
		
		slipraten = fvd(4,2,2) - fvd(4,1,2)
		sliprates = fvd(5,2,2) - fvd(5,1,2)
		sliprated = fvd(6,2,2) - fvd(6,1,2)
		fric(74,i,ift) = sliprates  !save for final slip output
		fric(75,i,ift) = sliprated
		sliprate = sqrt(slipraten**2+sliprates**2+sliprated**2)
			sliprate_arr(i) = sliprate
		if (sliprate>fric(76,i,ift)) then 
			fric(76,i,ift)=sliprate
		endif
		slipaccn=fvd(4,2,4)-fvd(4,1,4)
		slipaccs=fvd(5,2,4)-fvd(5,1,4)
		slipaccd=fvd(6,2,4)-fvd(6,1,4)
		!...path-itegrated slip for slip-weakening. B.D. 8/12/10
		slp4fri(i,ift) = slp4fri(i,ift) + sliprate * dtev1

		mslav = consm(1,isn)!mass(id(1,isn))		
		mmast = consm(1,imn)!mass(id(1,imn))
		mtotl = mslav + mmast
		if (mmast==0.0d0.or.mslav==0.0d0) then 
			write(*,*) 'ZERO MASS IN FAULTING, MMAST & MSLAV',mmast,mslav
			write(*,*) 'PROBLEMATIC COORDS ARE, X,Z =',x(1,isn)/1.0d3,x(3,isn)/1.0d3
			stop 501
		endif 
		!
		mtotl = mtotl * arn(i,ift)

		tnrm = (mslav*mmast*((fvd(4,2,2)-fvd(4,1,2))+(fvd(4,2,3)-fvd(4,1,3))/dt)/dt &
			+ mslav*fvd(4,2,1) - mmast*fvd(4,1,1)) / mtotl + fnfault         
		tstk = (mslav*mmast*(fvd(5,2,2)-fvd(5,1,2))/dt + mslav*fvd(5,2,1) &
			- mmast*fvd(5,1,1)) / mtotl + fsfault
		tdip = (mslav*mmast*(fvd(6,2,2)-fvd(6,1,2))/dt + mslav*fvd(6,2,1) &
			- mmast*fvd(6,1,1)) / mtotl + fdfault
	
		ttao = sqrt(tstk*tstk + tdip*tdip) !total shear magnitude	    
		!
		!...friction law to determine friction coefficient
		!   slip-weakening only so far. B.D. 1/26/07
		!... based on choices, call corresponding friction laws.
		! B.D. 10/8/08
		if (friclaw==1.or.friclaw==2) then!Differ 1&2 and 3&4	
		!PART2:SLIP-WEAKENING
			if(friclaw == 1) then
				call slip_weak(slp4fri(i,ift),fric(1,i,ift),xmu)
			elseif(friclaw == 2) then
				trupt =  time - fnft(i,ift)
				call time_weak(trupt,fric(1,i,ift),xmu)
			endif

			if (C_Nuclea==1) then	
				if(r4nuc(i,ift)<=srcrad0) then !only within nucleation zone, do...
					tr=(r4nuc(i,ift)+0.081d0*srcrad0*(1.d0/(1.d0-(r4nuc(i,ift)/srcrad0)*(r4nuc(i,ift)/srcrad0))-1.d0))/(0.7d0*3464.d0)
				else
					tr=1.0d9 
				endif
				if(time<tr) then 
					fb=0.0d0
				elseif ((time<(tr+critt0)).and.(time>=tr)) then 
					fb=(time-tr)/critt0
				else 
					fb=1.0d0
				endif
				tmp1=fric(1,i,ift)+(fric(2,i,ift)-fric(1,i,ift))*fb
				tmp2=xmu
				xmu=min(tmp1,tmp2)  !minimum friction used. B.D. 2/16/13	
			endif

			if((tnrm+fric(6,i,ift))>0.d0) then
				tnrm0 = 0.0d0
			else
				tnrm0 = tnrm+fric(6,i,ift)
			endif
			taoc = fric(4,i,ift) - xmu *tnrm0
			!taoc = cohes - xmu * tnrm0
			!if(tnrm > 0) tnrm = 0   !norm must be <= 0, otherwise no adjust
			!taoc = fistr(5,i) - xmu * tnrm
			if(ttao > taoc) then
				tstk = tstk * taoc / ttao
				tdip = tdip * taoc / ttao
				if(fnft(i,ift)>600.d0) then	!fnft should be initialized by >10000
					if(sliprate >= 0.001d0) then	!first time to reach 1mm/s
						fnft(i,ift) = time	!rupture time for the node
					endif
				endif
			endif

			taox = (tnrm0*un(1,i,ift) + tstk*us(1,i,ift) + tdip*ud(1,i,ift))*arn(i,ift)
			taoy = (tnrm0*un(2,i,ift) + tstk*us(2,i,ift) + tdip*ud(2,i,ift))*arn(i,ift)
			taoz = (tnrm0*un(3,i,ift) + tstk*us(3,i,ift) + tdip*ud(3,i,ift))*arn(i,ift)
			
			ftix = (fnfault*un(1,i,ift) + fsfault*us(1,i,ift) + fdfault*ud(1,i,ift))*arn(i,ift)
			ftiy = (fnfault*un(2,i,ift) + fsfault*us(2,i,ift) + fdfault*ud(2,i,ift))*arn(i,ift)
			ftiz = (fnfault*un(3,i,ift) + fsfault*us(3,i,ift) + fdfault*ud(3,i,ift))*arn(i,ift)  

			right(id(1,isn)) = right(id(1,isn)) + taox - ftix
			right(id(2,isn)) = right(id(2,isn)) + taoy - ftiy
			right(id(3,isn)) = right(id(3,isn)) + taoz - ftiz
			right(id(1,imn)) = right(id(1,imn)) - taox + ftix
			right(id(2,imn)) = right(id(2,imn)) - taoy + ftiy
			right(id(3,imn)) = right(id(3,imn)) - taoz + ftiz
		elseif (friclaw==3.or.friclaw==4) then 	

		!---3.2: DECLARE THE TIME FOR RUPTURING.	
			if(fnft(i,ift)<0.0d0) then	!fnft should be initialized by >10000
				if(sliprate >= 0.001d0) then	!first time to reach 1mm/s
					fnft(i,ift) = time	!rupture time for the node
				endif
			endif	
		!---3.3: INITIATE [V_TRIAL],[SLIPRS_TRIAL],,[SLIPRD_TRIAL]
			v_trial=sliprate
			sliprs_trial=sliprates
			sliprd_trial=sliprated
			statetmp=fric(20,i,ift)
		!---3.4: FRICTIONAL/NON FRIVTIONAL REGION	
			if 	(abs(x(3,isn)) <= 40.0d3 .and. abs(x(1,isn)) <= 50.0d3) then 
		!---3.4.1: FRICTIONAL REGION CONTROLLED BY RSF. 

	!---3.4.1.2: Dynamic + NON-DYNAMIC PROCESS: [STATUS1]==0		
				tstk0 = (mslav * fvd(5,2,1) - mmast * fvd(5,1,1)) / mtotl + fsfault
				tdip0 = (mslav * fvd(6,2,1) - mmast * fvd(6,1,1)) / mtotl + fdfault	
				tnrm = (mslav * fvd(4,2,1) - mmast * fvd(4,1,1)) / mtotl + fnfault
				! fric(41,i,ift) is abs(KU)
				fric(41,i,ift) = sqrt((mslav * fvd(5,2,1) - mmast * fvd(5,1,1))**2 + (mslav * fvd(6,2,1) - mmast * fvd(6,1,1))**2) / (mmast + mslav) 
				ttao0 = sqrt(tstk0 * tstk0 + tdip0 * tdip0)		
				
				!theta = L/V + (theta - L/V)*dexp(-V*dtev1/L)
				!- fric(22): theta*
				!- fric(21): theta_dot
				!- [fric(11): L],[fric(12,i): V0]
	!---3.4.1.3: TO COMPUTE THETA*(t+1) [FRIC(22,:)] FOR ITAG==0, USING [V_TRIAL]=[CONSTRAINV] 
	!----------: THETA**(t+1) [FRIC(22,:)] FOR ITAG==1, , USING [V_TRIAL]={[CONSTRAINV]+[CONSTRAINVTMP]}*0.5	
				if (itag == 0) then 
					v_trial = sliprate
					fric(42,i,ift) = sliprate !Only record the final sliprate in fric(42,i) in the last time step.
					phi = dlog(fric(12,i,ift) * fric(20,i,ift) / fric(11,i,ift))
					if (v_trial * dtev1 / fric(11,i,ift) <= 1.0d-6) then 
						fric(22,i,ift) = dlog(dexp(phi)*(1-v_trial*dtev1/fric(11,i,ift)) + fric(12,i,ift)*dtev1/fric(11,i,ift))
						fric(22,i,ift) = fric(11,i,ift)/fric(12,i,ift)*dexp(fric(22,i,ift))
					elseif (v_trial * dtev1 / fric(11,i,ift) > 1.0d-6) then 
						fric(22,i,ift) = dlog(fric(12,i,ift)/v_trial + (dexp(phi)-fric(12,i,ift)/v_trial)*dexp(-v_trial*dtev1/fric(11,i,ift))) 
						fric(22,i,ift) = fric(11,i,ift)/fric(12,i,ift)*dexp(fric(22,i,ift))
					endif
				elseif (itag == 1) then 
					do j=1,2  !1-slave, 2-master
						do k=1,3  !1-x comp, 2-y comp, 3-z comp 
							fvd(k,j,2) = consvtmp(k,nsmp(j,i,ift)) !2-vel
						enddo
					enddo	
					do k=1,2  !1-slave,2-master
						fvd(4,k,2) = fvd(1,k,2)*un(1,i,ift) + fvd(2,k,2)*un(2,i,ift) + fvd(3,k,2)*un(3,i,ift)  !4-norm
						fvd(5,k,2) = fvd(1,k,2)*us(1,i,ift) + fvd(2,k,2)*us(2,i,ift) + fvd(3,k,2)*us(3,i,ift)  !5-strike
						fvd(6,k,2) = fvd(1,k,2)*ud(1,i,ift) + fvd(2,k,2)*ud(2,i,ift) + fvd(3,k,2)*ud(3,i,ift)  !6-dip
					enddo	
					slipraten = fvd(4,2,2) - fvd(4,1,2)
					sliprates = fvd(5,2,2) - fvd(5,1,2)
					sliprated = fvd(6,2,2) - fvd(6,1,2)
					v_trial = sqrt(slipraten**2+sliprates**2+sliprated**2)		
					phi = dlog(fric(12,i,ift) * fric(20,i,ift) / fric(11,i,ift))
					if (v_trial * dtev1 / fric(11,i,ift) <= 1.0d-6) then 
						fric(22,i,ift) = dlog(dexp(phi)*(1-v_trial*dtev1/fric(11,i,ift)) + fric(12,i,ift)*dtev1/fric(11,i,ift))
						fric(22,i,ift) = fric(11,i,ift)/fric(12,i,ift)*dexp(fric(22,i,ift))
					elseif (v_trial * dtev1 / fric(11,i,ift) > 1.0d-6) then 
						fric(22,i,ift) = dlog(fric(12,i,ift)/v_trial + (dexp(phi)-fric(12,i,ift)/v_trial)*dexp(-v_trial*dtev1/fric(11,i,ift))) 
						fric(22,i,ift) = fric(11,i,ift)/fric(12,i,ift)*dexp(fric(22,i,ift))
					endif		
				endif

				T_coeff = 3464.0d0*2670.0d0/2.0d0 
				
				do iv = 1,ivmax	
					if(friclaw == 3) then
						call rate_state_ageing_law(v_trial,fric(22,i,ift),fric(1,i,ift),xmu,dxmudv) !RSF
					elseif(friclaw == 4) then
						call rate_state_slip_law(v_trial,fric(22,i,ift),fric(1,i,ift),xmu,dxmudv) !RSF
					endif 	
					tau_fric_trial = fric(4,i,ift) - xmu * tnrm0
					
					rsfeq = (tau_fric_trial-ttao0) + v_trial*T_coeff
					drsfeqdv = -dxmudv * tnrm0 +  1.0d0*T_coeff
									
				!if(abs(rsfeq/drsfeqdv) < 1.d-14 * abs(v_trial).and. abs(rsfeq) < 1.d-6 * abs(v_trial)) exit 
					if (abs(rsfeq) < 1.0d-10 * ttao0) exit
					
					vtmp = v_trial -  rsfeq / drsfeqdv
					
					if(vtmp <= 0.0d0) then
						v_trial = v_trial/2.0d0
					else
						v_trial = vtmp
					endif				
				enddo !iv	
				!if(v_trial < fric(19,i,ift)) then
				!	v_trial = fric(19,i,ift)
				!	tau_fric_trial = ttao0
				!endif	
				
				tstk=tau_fric_trial*tstk0/ttao0
				tdip=tau_fric_trial*tdip0/ttao0
				ttao=sqrt(tstk**2+tdip**2)
				fric(26,i,ift)=v_trial
				fric(28,i,ift)=tstk
				fric(29,i,ift)=tdip
				fric(30,i,ift)=tnrm0
				slipratemast=(v_trial)*mslav/(mmast+mslav)
				sliprateslav=-(v_trial)*mmast/(mmast+mslav)

				v_s_new_mast=slipratemast*tstk/ttao
				v_d_new_mast=slipratemast*tdip/ttao
				v_s_new_slav=sliprateslav*tstk/ttao
				v_d_new_slav=sliprateslav*tdip/ttao
				vxm=v_s_new_mast*us(1,i,ift)+v_d_new_mast*ud(1,i,ift)
				vym=v_s_new_mast*us(2,i,ift)+v_d_new_mast*ud(2,i,ift)
				vzm=v_s_new_mast*us(3,i,ift)+v_d_new_mast*ud(3,i,ift)
				vxs=v_s_new_slav*us(1,i,ift)+v_d_new_slav*ud(1,i,ift)
				vys=v_s_new_slav*us(2,i,ift)+v_d_new_slav*ud(2,i,ift)
				vzs=v_s_new_slav*us(3,i,ift)+v_d_new_slav*ud(3,i,ift)
	!---3.4.1.5: V* FOR ITAG==0 AND V** FOR ITAG==1 OBTAINED. 			
				! if (x(1,isn) == -20.0d3.and.x(3,isn)==-10.0d3) then 
					! write(*,*) 'v_trial', v_trial, 'itag',itag
					! write(*,*) 'tstk,tdip',tstk/1e6, tdip/1e6
							! do j=1,4    !1-force,2-vel,3-disp,4-acc
								! do k=1,2  !1-slave,2-master
									! write(*,*) fvd(4,k,j), fvd(5,k,j), fvd(6,k,j) 
								! enddo
							! enddo
				! endif 
				if (itag == 0) then 		
					consvtmp(1,imn)=vxm
					consvtmp(2,imn)=vym 
					consvtmp(3,imn)=vzm 
					consvtmp(1,isn)=vxs
					consvtmp(2,isn)=vys 
					consvtmp(3,isn)=vzs 	
				elseif (itag == 1) then 
					fric(20,i,ift) = fric(22,i,ift)
					ma_bar_ku_arr(i) = (v_trial - fric(42,i,ift)) / dtev1 * mmast * mslav / (mmast + mslav) / fric(41,i,ift)
					ma_bar_ku_arr(i) = abs(ma_bar_ku_arr(i))
					momrate_arr(i) =0.0d0 
					if ((abs(x(1,isn))<=34.0d3).and.(abs(x(3,isn)) < 20.0d3)) then
						momrate_arr(i) = 3464.0d0**2*2670.0d0*v_trial*dx*dx
					endif
					
					ruptarea_arr(i) = 0.0d0
					taoruptarea_arr(i) = 0.0d0
					slipruptarea_arr(i) = 0.0d0
					
					if (v_trial>=slipr_thres) then
						ruptarea_arr(i) = dx*dx
						taoruptarea_arr(i) = ttao*dx*dx
						slipruptarea_arr(i) = slip*dx*dx
					endif
									
					consv(1,imn)=vxm
					consv(2,imn)=vym 
					consv(3,imn)=vzm 
					consv(1,isn)=vxs
					consv(2,isn)=vys 
					consv(3,isn)=vzs 	
					
					fric(31,i,ift) = vxm 
					fric(32,i,ift) = vym 
					fric(33,i,ift) = vzm 
					fric(34,i,ift) = vxs
					fric(35,i,ift) = vys 
					fric(36,i,ift) = vzs 
				endif 
		!---3.4.1.6: WHEN ITAG==0, SIMPLY STORE V* INTO [CONSTRAINVTMP]
		!----------: WHEN ITAG==1, DECLARE [FRIC(22,:)] AND FINAL V** INTO [CONSTRAINV]			

			else ! The if for fault regions.
		! !---3.4.2: LOADING BOTTOM AT A FIXED SLIDING RATE	
				 tstk0=2.585534683723515d7/2.0d0
				 tdip0=0.0d6
				 tnrm=-25.0d6	 
				 if((tnrm+fric(6,i,ift))>0) then
					 tnrm0 = 0.0d0
				 else
					 tnrm0 = tnrm+fric(6,i,ift)
				 endif
				 
				 v_trial = 1.0d-9
				 fric(26,i,ift) = v_trial
				 fric(28,i,ift) = tstk0
				 fric(29,i,ift) = tdip0
				 fric(30,i,ift) = tnrm0
				 slipratemast=(v_trial)*mslav/(mmast+mslav)
				 sliprateslav=-(v_trial)*mslav/(mmast+mslav)
				 v_s_new_mast=slipratemast
				 v_d_new_mast=0.0d0
				 v_s_new_slav=sliprateslav
				 v_d_new_slav=0.0d0
				 vxm=v_s_new_mast*us(1,i,ift)+v_d_new_mast*ud(1,i,ift)
				 vym=v_s_new_mast*us(2,i,ift)+v_d_new_mast*ud(2,i,ift)
				 vzm=v_s_new_mast*us(3,i,ift)+v_d_new_mast*ud(3,i,ift)
				 vxs=v_s_new_slav*us(1,i,ift)+v_d_new_slav*ud(1,i,ift)
				 vys=v_s_new_slav*us(2,i,ift)+v_d_new_slav*ud(2,i,ift)
				 vzs=v_s_new_slav*us(3,i,ift)+v_d_new_slav*ud(3,i,ift)
				 
				 consvtmp(1,imn)=vxm
				 consvtmp(2,imn)=vym 
				 consvtmp(3,imn)=vzm 
				 consvtmp(1,isn)=vxs
				 consvtmp(2,isn)=vys 
				 consvtmp(3,isn)=vzs 
				
				 consv(1,imn)=vxm
				 consv(2,imn)=vym 
				 consv(3,imn)=vzm 
				 consv(1,isn)=vxs
				 consv(2,isn)=vys 
				 consv(3,isn)=vzs 	
				fric(31,i,ift) = vxm 
				fric(32,i,ift) = vym 
				fric(33,i,ift) = vzm 
				fric(34,i,ift) = vxs
				fric(35,i,ift) = vys 
				fric(36,i,ift) = vzs
				 
			endif	


			dtev1D(i)=ksi*fric(11,i,ift)/v_trial
			if (dtev1D(i) < 0) then
				write(*,*) 'NEGATIVE SLIPRATE, ITS LOC = ', x(1,isn),x(3,isn)
				write(*,*) 'PROBLEMATIC V_TRIAL = ', v_trial
				stop 502
			endif
			! Record rupture area, average stress vector, slip
			if (itag==1) then
			fric(82,i,ift) = sqrt(slips**2 + slipn**2) ! Total slip
				if (fric(26,i,ift) > 1.0d-3) then 
					fric(81,i,ift) = arn(i,ift) ! Record ruptured area
				endif 
				if (abs(tdynastart-time)<dt/100.0) then 
					fric(83,i,ift) = sqrt(fric(28,i,ift)**2 + fric(29,i,ift)**2) !Total shear traction when dyna starts.
				endif
				if (abs(tdynaend-time)<dt/100.0) then 
					fric(84,i,ift) = sqrt(fric(28,i,ift)**2 + fric(29,i,ift)**2) !Total shear traction when dyna ends.	
				endif					
			endif 
		endif

		if (itag==1) then
			if(n4onf>0) then
				do j=1,n4onf
					if(anonfs(1,j)==i.and.anonfs(3,j)==ift) then !only selected stations. B.D. 10/25/09    
						fltsta(1,it,j)  = time
						fltsta(2,it,j)  = v_trial
						fltsta(3,it,j)  = sliprated
						fltsta(4,it,j)  = fric(20,i,ift)
						fltsta(5,it,j)  = slips
						fltsta(6,it,j)  = slipd
						fltsta(7,it,j)  = slipn
						fltsta(8,it,j)  = fric(28,i,ift)!tstk
						fltsta(9,it,j)  = fric(29,i,ift)!tdip
						fltsta(10,it,j) = tnrm0
					endif
				enddo 
			endif   
		endif
		
		
	enddo	!ending i
enddo ! ending ift

	call output_prof

	if (itag==1) then
		pma = maxval(ma_bar_ku_arr)
		maxsliprate = maxval(sliprate_arr) 
		loc = maxloc(sliprate_arr)
		!write(*,*) 'maxsliprate at ', loc(1)
		totmomrate = sum(momrate_arr)
		totruptarea = sum(ruptarea_arr)
		tottaoruptarea = sum(taoruptarea_arr)
		totslipruptarea = sum(slipruptarea_arr)
	endif 		
	
	dtev=minval(dtev1D)
!-------------------------------------------------------------------!	
end subroutine faulting	 