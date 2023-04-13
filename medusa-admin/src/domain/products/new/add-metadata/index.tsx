import { useFieldArray, useWatch } from "react-hook-form"
import IconTooltip from "../../../../components/molecules/icon-tooltip"
import { NestedForm } from "../../../../utils/nested-form"
import Metadata, {
  MetadataField,
} from "../../../../components/organisms/metadata"
import { useEffect, useLayoutEffect, useState } from "react"

export type AddMetadataFormType = {
  data: MetadataField[]
}

type Props = {
  form: NestedForm<AddMetadataFormType>
}

const AddMetadataForm = ({ form }: Props) => {
  const { path, register, control } = form
  const { replace: replaceMetadata } = useFieldArray({
    control,
    name: path("data"),
    shouldUnregister: true,
  })
  const watchedMetadata = useWatch({
    control: control,
    name: path("data"),
  })
  const [metadata, setMetadata] = useState<MetadataField[]>(watchedMetadata)

  useEffect(() => {
    register(path("data"))
  }, [])

  useLayoutEffect(() => {
    replaceMetadata(metadata)
  }, [metadata])

  return (
    <>
      <div>
        <div className="flex items-center gap-x-2xsmall">
          <h3 className="inter-base-semibold">Product metadata</h3>
          <IconTooltip
            type="info"
            content="Metadata are used to define specifications"
          />
        </div>
        <div className="mt-xlarge w-full">
          <Metadata setMetadata={setMetadata} metadata={metadata} />
        </div>
      </div>
    </>
  )
}

export default AddMetadataForm
