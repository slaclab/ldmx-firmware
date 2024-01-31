#import pprint

def createPvMap(prefix, root):
    # SVT:lv:0:0:avdd:i_rd - hybrid avdd current
    d = {}

    d[root.GitVersion.path] = f'{prefix}:daq:hpsrogue:version'
    d[root.LibRogueVersion.path] = f'{prefix}:daq:librogue:version'
    d[root.RogueCodaVersion.path] = f'{prefix}:daq:roguecoda:version'
    d[root.LibRogueLiteVersion.path] = f'{prefix}:daq:libroguelite:version'

    d[root.GlobalHybridPwrSwich.path] = f'{prefix}:lv:all:switch'
    for i, feb in root.FebArray.FebFpga.items():
        d[feb.FebCore.FebConfig.HybridPwrAll.path] = f'{prefix}:lv:{i}:all:switch'
        d[feb.AxiVersion.GitHash.path] = f'{prefix}:daq:fe:{i}:githash'

        d[feb.FebSem.SemStatus.path] = f'{prefix}:daq:fe:{i}:seu_status'
        d[feb.FebSem.Essential.path] = f'{prefix}:daq:fe:{i}:seu_seen'
        d[feb.FebSem.Uncorrectable.path] = f'{prefix}:daq:fe:{i}:seu_stuck'
        d[feb.FebSem.CorrectionCount.path] = f'{prefix}:daq:fe:{i}:seu_count'


        for j, status in feb.FebCore.HybridPowerControl.items():
            pass #d[status.HybridOnStatus.path] = f'{prefix}:lv:{i}:{j}:stat:curr'
        for j, enable in feb.FebCore.FebConfig.HybridPwrEn.items():
            d[enable.path] = f'{prefix}:lv:{i}:{j}:all:switch'
        for j, hybrid in feb.FebCore.HybridPowerControl.items():
            d[hybrid.AVDD.Current.path] = f'{prefix}:lv:{i}:{j}:avdd:i_rd'
            d[hybrid.DVDD.Current.path] = f'{prefix}:lv:{i}:{j}:dvdd:i_rd'
            d[hybrid.V125.Current.path] = f'{prefix}:lv:{i}:{j}:v125:i_rd'

            d[hybrid.AVDD.Trim.path] = f'{prefix}:lv:{i}:{j}:avdd:v_set_rd'
            d[hybrid.DVDD.Trim.path] = f'{prefix}:lv:{i}:{j}:dvdd:v_set_rd'
            d[hybrid.V125.Trim.path] = f'{prefix}:lv:{i}:{j}:v125:v_set_rd'

            d[hybrid.AVDD.VoltageNear.path] = f'{prefix}:lv:{i}:{j}:avdd:vn'
            d[hybrid.DVDD.VoltageNear.path] = f'{prefix}:lv:{i}:{j}:dvdd:vn'
            d[hybrid.V125.VoltageNear.path] = f'{prefix}:lv:{i}:{j}:v125:vn'

            d[hybrid.AVDD.VoltageFar.path] = f'{prefix}:lv:{i}:{j}:avdd:vf'
            d[hybrid.DVDD.VoltageFar.path] = f'{prefix}:lv:{i}:{j}:dvdd:vf'
            d[hybrid.V125.VoltageFar.path] = f'{prefix}:lv:{i}:{j}:v125:vf'

            d[hybrid.AVDD.PGood.path] = f'{prefix}:lv:{i}:{j}:avdd:stat'
            d[hybrid.DVDD.PGood.path] = f'{prefix}:lv:{i}:{j}:dvdd:stat'
            d[hybrid.V125.PGood.path] = f'{prefix}:lv:{i}:{j}:v125:stat'

        for j, hybrid in feb.FebCore.Hybrid.items():
            d[hybrid.Temperature0.path] = f'{prefix}:temp:hyb:{i}:{j}:temp0:t_rd'
            d[hybrid.Temperature1.path] = f'{prefix}:temp:hyb:{i}:{j}:temp1:t_rd'

        d[feb.FebCore.BoardPowerMonitor.FebFpgaTemp.path] = f'{prefix}:temp:fe:{i}:axixadc:t_rd'
        d[feb.FebCore.BoardPowerMonitor.FebTemp0.path] = f'{prefix}:temp:fe:{i}:FebTemp0:t_rd'
        d[feb.FebCore.BoardPowerMonitor.FebTemp1.path] = f'{prefix}:temp:fe:{i}:FebTemp1:t_rd'
        d[feb.FebCore.BoardPowerMonitor.FebVccInt.path] = f'{prefix}:power:fe:{i}:d1p0vint:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebVccAux.path] = f'{prefix}:power:fe:{i}:d2p5vaux:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA6V.path] = f'{prefix}:power:fe:{i}:a6v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA5V.path] = f'{prefix}:power:fe:{i}:a5p0v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebD33V.path] = f'{prefix}:power:fe:{i}:d3p3v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA22V.path] = f'{prefix}:power:fe:{i}:a2p2v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA29VA.path] = f'{prefix}:power:fe:{i}:a2p9va:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA29VD.path] = f'{prefix}:power:fe:{i}:a2p9vd:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA16V.path] = f'{prefix}:power:fe:{i}:a1p6v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebD6V.path] = f'{prefix}:power:fe:{i}:d6v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebD25V.path] = f'{prefix}:power:fe:{i}:d2p5v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebD12V_MGT.path] = f'{prefix}:power:fe:{i}:d1p2vmgt:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebD10V_MGT.path] = f'{prefix}:power:fe:{i}:d1p0vmgt:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebA18V.path] = f'{prefix}:power:fe:{i}:a1p8v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebAN6V.path] = f'{prefix}:power:fe:{i}:an6v:v_rd'
        d[feb.FebCore.BoardPowerMonitor.FebAN5V.path] = f'{prefix}:power:fe:{i}:an5p0v:v_rd'

        for j, hybrid in feb.FebCore.HybridSyncStatus.items():
            d[hybrid.SyncDetected.path] = f'{prefix}:lv:{i}:{j}:sync:sync_rd'

            for k, base in hybrid.Base.items():
                d[base.path] = f'{prefix}:daq:{i}:{j}:{k}:syncbase_rd'

            for k, peak in hybrid.Peak.items():
                d[peak.path] = f'{prefix}:daq:{i}:{j}:{k}:syncpeak_rd'

    for i, dpm in root.DataDpmArray.DataDpm.items():
        d[dpm.RceVersion.GitHash.path] = f'{prefix}:daq:datadpm:{i}.githash'
        for j, dp in dpm.RceCore.DataPath.items():
            d[dp.FebNum.path] = f'{prefix}:daq:dpm:{i}:{j}:febnum'
            d[dp.HybridNum.path] = f'{prefix}:daq:dpm:{i}:{j}:hynum'

        d[dpm.RceCore.EventBuilder.State.path] = f'{prefix}:daq:dpm:{i}:eventstate'
        d[dpm.RceCore.EventBuilder.EventCount.path] = f'{prefix}:daq:dpm:{i}:eventcount'
        d[dpm.RceCore.EventBuilder.BurnCount.path] = f'{prefix}:daq:dpm:{i}:burncount'
        d[dpm.RceCore.EventBuilder.SampleCountLast.path] = f'{prefix}:daq:dpm:{i}:occupancy'
        d[dpm.RceCore.EventBuilder.PeakOccupancy.path] = f'{prefix}:daq:dpm:{i}:peakoccupancy'
        d[dpm.RceCore.EventBuilder.SyncErrorCount.path] = f'{prefix}:daq:dpm:{i}:syncerrorcount'
        d[dpm.RceCore.EventBuilder.HeadErrorCount.path] = f'{prefix}:daq:dpm:{i}:headerrorcount'
        d[dpm.RceCore.EventBuilder.EventErrorCount.path] = f'{prefix}:daq:dpm:{i}:ebeventerrorcount_rd'


        for j, link in dpm.PgpStatus.Pgp2bAxi.items():
            d[link.RxLinkErrorCount.path] = f'{prefix}:daq:dpm:{i}:{j}:rxlinkerrorcount'
            d[link.RxFrameCount.path] = f'{prefix}:daq:dpm:{i}:{j}:rxframecount'
            d[link.RxFrameErrorCount.path] = f'{prefix}:daq:dpm:{i}:{j}:rxframeerrorcount'
            d[link.RxLinkDownCount.path] = f'{prefix}:daq:dpm:{i}:{j}:rxlinkdowncount'
            d[link.RxPhyReady.path] = f'{prefix}:daq:dpm:{i}:{j}:rxphyready'

    for i, dpm in root.ControlDpm.items():
        d[dpm.RceVersion.GitHash.path] = f'{prefix}:daq:controldpm:{i}:githash'

    for i, dtm in root.PcieTiDtmArray.PcieTiDtm.items():
        d[dtm.RceVersion.GitHash.path] = f'{prefix}:daq:dtm:{i}:githash'
        d[dtm.JLabTimingPcie.BusyTime.path] = f'{prefix}:daq:dtm:{i}:filterbusyrate'
        d[dtm.JLabTimingPcie.CodaState.path] = f'{prefix}:daq:dtm:{i}:state'
        d[dtm.JLabTimingPcie.TiTriggerCount.path] = f'{prefix}:daq:dtm:{i}:trigcount'

    for i, link in root.FebLinkStatus.Link.items():
        d[link.path] = f'{prefix}:feb:{i}:linkstatus'

#    pprint.pprint(d)
    return d
