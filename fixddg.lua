-- .fixddg
-- Try to getimpro by finding hydrophilic segments in the
-- target protein  that are near segments in the user protein
-- and mutating the user protein segment  to something that can 
-- bond with that target; keeping changes that improve our ddg
-- score
--
-- version 1.0
-- * converted from UnBun..

iterations=2        -- iterations for shake and wiggle
bond_radius=9.6     -- how close segments have to be to try to make bonds
do_wiggle_all=false -- include a WiggleAll() to try to get a bond
select_window=4     -- how many adjacent segments to wiggle in each direction
start_percent=0       -- start a percentage through target 

function do_dialog()
    local ask = dialog.CreateDialog("FixDDG Tunables")
    ask.Instructions = dialog.AddLabel("Set the values as needed")
    ask.Iterations = dialog.AddSlider("Iterations",iterations,1,10,0)
    ask.SelectWindow = dialog.AddSlider("Select Window",select_window,1,20,0)
    ask.Radius = dialog.AddSlider("Proximity Radius", bond_radius, 4,15,1)
    ask.WiggleAll = dialog.AddCheckbox("Include WiggleAll", false)
    ask.Startpercent = dialog.AddSlider("Start at percent",start_percent,0,100,1)
    ask.WiggleInfo = dialog.AddLabel("Turn off WiggleAll for endgame")
    ask.OK = dialog.AddButton("OK",1)
    if dialog.Show(ask) > 0 then
         iterations = ask.Iterations.value
         bond_radius = ask.Radius.value
         do_wiggle_all = ask.WiggleAll.value
         select_window = ask.SelectWindow.value
         start_percent = ask.Startpercent.value
    end
end

function GetBondableAcids(acid)
    -- if this is a "red" acid, return the list of blue ones
    -- and vice versa; if its a red-blue one return both
    -- and if its a M, return the same...
    if acid == 'k' or acid == 'r' or acid == 'h' or acid == 'w' then
        return {'e','d','s','t','y'}
    end
    if acid == 'e' or acid== 'd' or acid =='s' or acid == 't' or acid == 'y' then
        return {'k','r','h','w'}
    end
    if acid == 'm' then
        return {'m'}
    end
    -- otherwise pretend its a red-blue, and try lots..
    return {'k','r','h','w','e','d','s','t','y'}
end

function find_filter()
    -- first find the ddg filter so we can check for improvement
    --
    satfilt = -1
    filt = filter.GetNames ()
    print ( #filt .. " conditions or filters" )
    for ii = 1, #filt do
        print( "checking filter " .. ii .. ": " .. filt[ii] )
        if string.match(filt[ii],".*DDG") then
            print( "found ddg filter " )
            satfilt = ii
        end
    end
end

function delay2() 
   local xyzzy
   for i=1,1000 do
      xyzzy=5
   end
end

function delay()
   for i=1,10  do
       delay2()
   end
end


function do_fixddg()
    if satfilt >= 0 then
       do_estimates()
       do_target_bonds()  
    else
        print( "Couldn't find sat filter, quitting" )
    end
end

function do_estimates()
    nsegs = structure.GetCount()
    -- guess that the boundary between target and user segments is halfway
    -- we'll move it as we see mutable / non mutables...
    boundary = math.floor( nsegs/2 )
    orig_nsat_bonus = filter.GetBonus(filt[satfilt])
    print("estimating effort:")
    
    saw_mutable = false
    move_boundary = 0
    -- find actual boundary; our first mutable past halfway...
    for ups = boundary, nsegs do
        if not saw_mutable and not structure.IsMutable(ups) then
            move_boundary = move_boundary + 1
        end
        if not saw_mutable and structure.IsMutable(ups) then
            saw_mutable = true
            break
        end 
    end
    if boundary + move_boundary < nsegs then
        boundary = boundary + move_boundary
    end
    -- estmiate work to be done
    wiggles_estimated = 1
    for tps = 1, boundary do
        pest = math.floor(tps * 100 / boundary)
        if tps % 15 == 1 then
            print("estimating: ["..pest.."%]")
        end
        if not structure.IsHydrophobic(tps) then
            taa = structure.GetAminoAcid(tps)
            bonding_acids = GetBondableAcids(taa)
            for ups = boundary, nsegs do
                if not saw_mutable and not structure.IsMutable(ups) then
                    move_boundary = move_boundary + 1
                end
                if not saw_mutable and structure.IsMutable(ups) then
                    saw_mutable = true
                end 
                if structure.IsMutable(ups) and structure.GetDistance(tps, ups) < bond_radius and string.len(taa) == 1 then
                   wiggles_estimated = wiggles_estimated + #bonding_acids
                end
            end
        end
    end
end

function do_target_bonds()
    print("Part 2(2) Trying to find bonds for Hydrophobics in  first " .. boundary .. " segments...")
    print("Estimating " .. wiggles_estimated .. " wiggles of " .. iterations .. " iterations")
    -- now start Real Work...

    -- we used to just start everything at zero,but  allowing ourselves
    -- to start partway through means we need to fudge here
    start = math.floor(1 + start_percent * boundary / 100.0)
    wiggles_done = math.floor(wiggles_estimated * start_percent / 100.0)

    for tps = 1, boundary-1 do
        if not structure.IsHydrophobic(tps) then
            -- look up amino acids to try against this protein
            taa = structure.GetAminoAcid(tps)
            bonding_acids = GetBondableAcids(taa)
            pdone = math.floor(100 * wiggles_done / wiggles_estimated)
        
            for ups = boundary, nsegs do
                maxbonusacid = structure.GetAminoAcid(ups)
                if structure.IsMutable(ups) and structure.GetDistance(tps, ups) < bond_radius and string.len(maxbonusacid) == 1 then
                    print("["..pdone.."%] Segment " .. ups .. " acid " .. maxbonusacid .. " is within " .. bond_radius ..  " of polar segment " .. tps)
                    segments_tried = segments_tried + 1
                    -- keep max bonus and corresponding protein
                    -- max (so far) is where we are now
                    delay()
                    max_nsat_bonus = filter.GetBonus(filt[satfilt])
                    recentbest.Save()
                    save.Quicksave(99)
                    selection.DeselectAll()
                    selection.Select(tps)
                    selection.Select(ups)
                    for ii = 1, select_window do
                        if ups + ii <= nsegs then
                            selection.Select(ups+ii)
                        end
                        if ups - ii >= boundary then
                            selection.Select(ups-ii)
                        end
                    end
                   
                    print( "["..pdone.."%] Trying each of: ".. table.concat(bonding_acids,',') )
                    for bai = 1,#bonding_acids do
                        wiggles_done = wiggles_done + 1
                        pdone = math.floor(100 * wiggles_done / wiggles_estimated)
                        structure.SetAminoAcid(ups, bonding_acids[bai])
                        -- sometimes just mutating it adds a bond, so skip shake and or wiggle if
                        -- the score is already better...
                        delay()
                        bonus = filter.GetBonus(filt[satfilt])
                        if false and  bonus <= max_nsat_bonus then
                            -- maybe if we shake it it will bond?
                            structure.ShakeSidechainsSelected(iterations)
                            delay()
                            bonus = filter.GetBonus(filt[satfilt])
                            
                        end
                        if bonus <= max_nsat_bonus then
                            --  see if wiggling with the band will bond it...
                            -- try to band the sidechains so wiggle will try to make the bond
                            tcount = structure.GetAtomCount(tps)
                            ucount = structure.GetAtomCount(ups)

                            band_ok,myband = pcall(band.AddBetweenSegments, tps, ups, tcount, ucount)
                            if band_ok and myband > 0 then
                                band.SetGoalLength(myband,1.6)
                                band.SetStrength(myband, 1.3)
                            else
                                band_ok = false
                                myband = -1
                            end

                            -- wiggle just sidechains first, so we get as
                            -- close as possible without bending the 
                            -- backbone
                            
                            structure.LocalWiggleSelected(iterations,false,true)
                            delay()
                            bonus = filter.GetBonus(filt[satfilt])
                            if bonus <= max_nsat_bonus then
                               structure.LocalWiggleSelected(iterations,true,true)
                               delay()
                               bonus = filter.GetBonus(filt[satfilt])
                            end
                            if do_wiggle_all and bonus <= max_nsat_bonus then
                               structure.WiggleAll(iterations)
                            end
                            -- Foldit keeps hanging or missing band deletes when we do it right away, so
                            delay()
                            
                            if band_ok then
                               band.Delete(myband)
                            end

                            myband = -1

                            bonus = filter.GetBonus(filt[satfilt])
                        end

                        if bonus > max_nsat_bonus then
                            -- we have a new winner!!!
                            maxbonusacid = bonding_acids[bai]
                            max_nsat_bonus = bonus
                            recentbest.Save()
                            save.Quicksave(99)
                            print("new best!  BUNS score: ".. bonus)
                            break
                        else
                            -- our bonus is equal, but... 
                            -- if we improved  the overall score , keep the wiggle anyway
                            if current.GetEnergyScore() > recentbest.GetEnergyScore() then
                                recentbest.Save()
                                save.Quicksave(99)
                            else
                                save.Quickload(99)
                            end
                        end
                    end
                end
            end
        end
    end
    if segments_tried == 0 then
        print("No segments found within bond_raius of " .. bond_radius .. ".")
        print("edit recipe and increase bond_radius.")
    end
end

function cleanup( error )
    -- if anything happens, or we cancel, fall back to our recentbest
    -- and get rid of the band we may have left.
    --

    if IN_CLEANUP ~= nil then
        return
    end
    IN_CLEANUP = true
    
    print("Cleaning up: "..error)
    -- Foldit keeps hanging when we do stuff too soon after
    -- Wiggle-ing so
    delay()
    delay()
    delay()
    -- THEN
    if myband > -1 then
        print("removing band")
        band.Delete(myband)
    end
    print("turning undo back on...")
    undo.SetUndo(true)
    print("restoring best position")
    save.Quickload(99)
    print("Done!")
end

function fixddg_main()
    do_dialog()
    print("fixddg: starting with iterations=" .. iterations .. " and bond_radius=" .. bond_radius )
    myband = -1
    segments_tried = 0
    undo.SetUndo(false)
    recipe.SectionStart("fixddg")
    recentbest.Save()
    save.Quicksave(99)
    find_filter()
    -- should be done as below, but this hangs for me
    xpcall(do_fixddg, cleanup)
    -- instead:
    -- do_fixddg()
    cleanup("Finished")
    recipe.ReportStatus()
    recipe.SectionEnd()
end

fixddg_main()




